resource "aws_security_group" "control-server" {
  name        = "control-server-security-group"
  description = "Allow SSH, HTTP, and Minikube traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["219.74.49.109/32"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["219.74.49.109/32", "185.199.108.0/22", "143.55.64.0/20", "192.30.252.0/22", "140.82.112.0/20"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["219.74.49.109/32", "18.143.208.67/32", "103.189.63.82/32", "122.11.214.20/32", "185.199.108.0/22", "143.55.64.0/20", "192.30.252.0/22", "140.82.112.0/20", "121.7.129.81/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["185.199.108.0/22", "143.55.64.0/20", "192.30.252.0/22", "140.82.112.0/20"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["185.199.108.0/22", "143.55.64.0/20", "192.30.252.0/22", "140.82.112.0/20"]
  }

  #ingress {
  #  from_port   = 0
  #  to_port     = 65535
  #  protocol    = "tcp"
  #  cidr_blocks = ["219.74.49.109/32"]
  #}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#resource "aws_security_group" "redis-cache" {
#  name        = "redis-cache-security-group"
#  description = "Allow redis cache traffic"
#  vpc_id      = aws_vpc.vpc.id
#
#  ingress {
#    from_port   = 6379
#    to_port     = 6379
#    protocol    = "tcp"
#    cidr_blocks = ["10.0.0.6/32", "10.0.176.0/27", "10.0.160.0/27"]
#  }
#
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#}
