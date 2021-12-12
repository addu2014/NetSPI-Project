provider "aws" {
  region     = "${var.region}"
  access_key = "${var.access_key_id}"
  secret_key = "${var.secret_key_id}"
}

data "aws_eip" "filter_eip" {
  filter {
    name   = "tag:Project"
    values = ["NetSPI_EIP"]
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${aws_instance.test.id}"
  allocation_id = "${data.aws_eip.filter_eip.id}"
}

resource "aws_instance" "test" {
  ami                    = "${var.ami_id}"
  instance_type          = "${var.instance_type}"
  key_name               = "test_project"
  subnet_id              = "${var.subnet}"    
  vpc_security_group_ids = ["sg-062c60edcb0ac6dc8"]


  tags = {
    Name = "test-instance"
  }
  depends_on = ["aws_efs_mount_target.efs"]
  connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("./test_project.pem")}"
      host        = "${self.public_ip}"
    }
  provisioner "remote-exec"{
      inline = [
          "sudo mkdir -p /data/test",
          "sudo apt update -y",
          "sudo apt install nfs-common -y",
          "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.test_efs.dns_name}:/ /data/test"
      ]
  }
}

resource "aws_efs_file_system" "test_efs" {
  creation_token = "test_efs"
}
resource "aws_efs_mount_target" "efs" {
  file_system_id  = "${aws_efs_file_system.test_efs.id}"
  subnet_id       = "${var.subnet}"
  security_groups = ["sg-062c60edcb0ac6dc8"]
}
output "efs_volume_id" {
  value = "${aws_efs_file_system.test_efs.id}"
}
output "ec2_instance_id" {
  value = "${aws_instance.test.id}"
}

