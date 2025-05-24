resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "employee-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "employee-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "employee-public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[0]  # First CIDR from list
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "employee-private-subnet-1"
  }

  # Explicit dependency to avoid race conditions
  depends_on = [aws_vpc.main]
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[1]  # Second CIDR from list
  availability_zone = "${var.aws_region}c"
  tags = {
    Name = "employee-private-subnet-2"
  }

  depends_on = [aws_vpc.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "employee-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}