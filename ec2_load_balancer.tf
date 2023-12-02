# Configuração de Launch Template e Auto Scaling para o Projeto Lucas
resource "aws_launch_template" "projeto_lucas_launch_template" {
  name_prefix   = "projeto-lucas-ec2-launch"
  image_id      = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro" 

  user_data = base64encode(<<-EOF
    #!/bin/bash
    export DEBIAN_FRONTEND=noninteractive
    
    sudo apt-get update
    sudo apt-get install -y python3-pip python3-venv git

    # Criação do ambiente virtual e ativação
    python3 -m venv /home/ubuntu/myappenv
    source /home/ubuntu/myappenv/bin/activate

    # Clonagem do repositório da aplicação
    git clone https://github.com/ArthurCisotto/aplicacao_projeto_cloud.git /home/ubuntu/myapp

    # Instalação das dependências da aplicação
    pip install -r /home/ubuntu/myapp/requirements.txt

    sudo apt-get install -y uvicorn
 
    # Configuração da variável de ambiente para o banco de dados
    export DATABASE_URL="mysql+pymysql://lucas_admin:lucas_senha@${aws_db_instance.projeto_lucas_rds.endpoint}/projeto_lucas_db"

    cd /home/ubuntu/myapp
    # Inicialização da aplicação
    uvicorn main:app --host 0.0.0.0 --port 80 
  EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.projeto_lucas_subnet_publica1.id
    security_groups             = [aws_security_group.projeto_lucas_ec2_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Projeto-Lucas-Instance"
    }
  }
}

resource "aws_autoscaling_group" "projeto_lucas_asg" {
  desired_capacity     = 2  # Alterado de 2 para 3
  max_size             = 6  # Alterado de 6 para 5
  min_size             = 2  # Alterado de 2 para 1
  vpc_zone_identifier  = [aws_subnet.projeto_lucas_subnet_publica1.id, aws_subnet.projeto_lucas_subnet_publica2.id]
  target_group_arns    = [aws_lb_target_group.projeto_lucas_alb_tg.arn]

  launch_template {
    id      = aws_launch_template.projeto_lucas_launch_template.id
    version = "$Latest"
  }

  # Políticas de Escalabilidade
  health_check_type          = "ELB"
  health_check_grace_period  = 300
  force_delete               = true

  tag {
    key                 = "Name"
    value               = "Lucas-ASG-Instance"
    propagate_at_launch = true
  }
}

# Application Load Balancer para o Projeto Lucas
resource "aws_lb" "projeto_lucas_alb" {
  name               = "projeto-lucas-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.projeto_lucas_alb_sg.id]
  subnets            = [aws_subnet.projeto_lucas_subnet_publica1.id, aws_subnet.projeto_lucas_subnet_publica2.id]
}

resource "aws_lb_target_group" "projeto_lucas_alb_tg" {
  name     = "projeto-lucas-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.projeto_lucas_vpc.id

  # Configuração de Health Checks
  health_check {
    enabled             = true
    interval            = 30  # Alterado de 30 para 25
    path                = "/healthcheck"
    protocol            = "HTTP"
    healthy_threshold   = 3  # Alterado de 3 para 2
    unhealthy_threshold = 3  # Alterado de 3 para 2
    timeout             = 5  # Alterado de 5 para 10
    matcher             = "200"
  }
}

resource "aws_lb_listener" "projeto_lucas_listener" {
  load_balancer_arn = aws_lb.projeto_lucas_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.projeto_lucas_alb_tg.arn
  }
}
