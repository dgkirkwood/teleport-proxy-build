packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}


source "amazon-ebs" "ubuntu" {
  ami_name      = "dk-teleport-target"
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
    inline = [
        "echo Installing Grafana...",
        "sudo apt-get install -y apt-transport-https",
        "sudo apt-get install -y software-properties-common wget",
        "wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -",
        "echo 'deb https://packages.grafana.com/oss/deb stable main' | sudo tee -a /etc/apt/sources.list.d/grafana.list",
        "sudo apt-get update",
        "sudo apt-get install -y grafana",
        "sudo systemctl enable grafana-server.service"
    ]
  }
  provisioner "file" {
    source = "config/grafana_node.yaml"
    destination = "~/grafana_node.yaml"
  }
  provisioner "file" {
    source = "config/ssh_node.yaml"
    destination = "~/ssh_node.yaml"
  }
  provisioner "shell" {
    inline = [
      "echo Moving config files...",
      "mkdir ~/configs",
      "sudo mv ~/grafana_node.yaml ~/configs/grafana_node.yaml",
      "sudo mv ~/ssh_node.yaml ~/configs/ssh_node.yaml"
    ]
  }
}
