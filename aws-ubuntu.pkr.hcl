packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ent_license" {
  default = env("ENT_LICENSE")
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "dk-teleport-proxy"
  instance_type = "t2.micro"
  region        = "ap-southeast-2"
  vpc_id = "vpc-04e78c4cc247da19a"
  subnet_id = "subnet-05060b931f314d650"
  associate_public_ip_address = true
  ssh_interface = "public_ip"
  force_deregister = true
  force_delete_snapshot = true
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  name    = "dk-teleport-proxy"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
  provisioner "shell" {
    inline = [
      "echo Installing Teleport....",
      "sudo curl https://deb.releases.teleport.dev/teleport-pubkey.asc -o /usr/share/keyrings/teleport-archive-keyring.asc",
      "echo 'deb [signed-by=/usr/share/keyrings/teleport-archive-keyring.asc] https://deb.releases.teleport.dev/ stable main' | sudo tee /etc/apt/sources.list.d/teleport.list > /dev/null",
      "sudo apt-get update",
      "sleep 10",
      "sudo apt-get install teleport"
    ]
  }
  provisioner "shell" {
    environment_vars = [
      "ENT_LICENSE=${var.ent_license}"
    ]
    inline = [
      "echo $ENT_LICENSE | sudo tee /var/lib/teleport/license.pem"
    ]
  }
  provisioner "file" {
    source = "config/proxy_teleport.yaml"
    destination = "/tmp/proxy_teleport.yaml"
  }
}
