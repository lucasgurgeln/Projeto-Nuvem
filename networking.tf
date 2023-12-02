# Configuração da VPC
resource "aws_vpc" "projeto_lucas_vpc" {
  cidr_block = "10.0.0.0/23"
  tags = {
    Name = "Projeto-Lucas-VPC"
  }
}

# Subnets Públicas
resource "aws_subnet" "projeto_lucas_subnet_publica1" {
  vpc_id                  = aws_vpc.projeto_lucas_vpc.id
  cidr_block              = "10.0.0.0/25"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "projeto_lucas_subnet_publica2" {
  vpc_id                  = aws_vpc.projeto_lucas_vpc.id
  cidr_block              = "10.0.0.128/25"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
}

# Subnets Privadas
resource "aws_subnet" "projeto_lucas_subnet_privada1" {
  vpc_id                  = aws_vpc.projeto_lucas_vpc.id
  cidr_block              = "10.0.1.0/25"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
}

resource "aws_subnet" "projeto_lucas_subnet_privada2" {
  vpc_id                  = aws_vpc.projeto_lucas_vpc.id
  cidr_block              = "10.0.1.128/25"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
}

# Internet Gateway
resource "aws_internet_gateway" "projeto_lucas_igw" {
  vpc_id = aws_vpc.projeto_lucas_vpc.id
}

# Security Group para EC2
resource "aws_security_group" "projeto_lucas_ec2_sg" {
  name        = "Projeto-Lucas-EC2-SG"
  description = "Security Group for EC2 Instances in Project Lucas"
  vpc_id      = aws_vpc.projeto_lucas_vpc.id

  # Regras de entrada (permitir tráfego HTTP)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regras de saída (liberar todo o tráfego)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group para ALB
resource "aws_security_group" "projeto_lucas_alb_sg" {
  name        = "Projeto-Lucas-ALB-SG"
  description = "Security Group for ALB in Project Lucas"
  vpc_id      = aws_vpc.projeto_lucas_vpc.id

  # Regras de entrada (permitir tráfego HTTP e HTTPS)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regras de saída (liberar todo o tráfego)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group para RDS
resource "aws_security_group" "projeto_lucas_rds_sg" {
  name        = "Projeto-Lucas-RDS-SG"
  description = "Security Group for RDS in Project Lucas"
  vpc_id      = aws_vpc.projeto_lucas_vpc.id

  # Regras de entrada (permitir tráfego MySQL)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.projeto_lucas_ec2_sg.id] # Permitir que as instâncias EC2 se conectem ao RDS
  }

  # Regras de saída (liberar todo o tráfego)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Tabelas de Rotas e Associações
resource "aws_route_table" "projeto_lucas_route_table" {
  vpc_id = aws_vpc.projeto_lucas_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.projeto_lucas_igw.id
  }
}

resource "aws_route_table_association" "projeto_lucas_rta_subnet_publica1" {
  subnet_id      = aws_subnet.projeto_lucas_subnet_publica1.id
  route_table_id = aws_route_table.projeto_lucas_route_table.id
}

resource "aws_route_table_association" "projeto_lucas_rta_subnet_publica2" {
  subnet_id      = aws_subnet.projeto_lucas_subnet_publica2.id
  route_table_id = aws_route_table.projeto_lucas_route_table.id
}
