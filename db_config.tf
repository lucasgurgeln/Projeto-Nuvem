# Configuração de um banco de dados RDS MySQL para o Projeto Lucas
resource "aws_db_instance" "projeto_lucas_rds" {
  db_name             = "projeto_lucas_db"
  allocated_storage   = 20
  storage_type        = "gp2"
  engine              = "mysql"
  engine_version      = "5.7"  
  instance_class      = "db.t2.micro"  
  username            = "lucas_admin" 
  password            = "lucas_senha"  
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.projeto_lucas_rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.projeto_lucas_subnet_group.name


  # Backup e Janela de Manutenção
  backup_retention_period = 7
  backup_window           = "02:00-03:00"  
  maintenance_window      = "Sat:05:00-Sat:06:00"  

  # Multi-AZ para Alta Disponibilidade
  multi_az = true
}

resource "aws_db_subnet_group" "projeto_lucas_subnet_group" {
  name       = "projeto-lucas-db-subnet-group"
  subnet_ids = [aws_subnet.projeto_lucas_subnet_privada1.id, aws_subnet.projeto_lucas_subnet_privada2.id]
  tags = {
    Name = "Projeto Lucas DB Subnet Group"
  }
}

