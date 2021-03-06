# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "${var.cidr_block}"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags {
    Name = "${var.environment} VPC"
    environment = "${var.environment}"
    project = "${var.project}"
    product = "${var.product}"
  }
}

# Create subnets
resource "aws_subnet" "main" {
  count = "${var.amount_subnets}"
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${element(split(",", var.subnets_cidr_block), count.index)}"
  availability_zone = "${concat(var.aws_region, element(split(",", var.subnets), count.index))}"

  tags {
    Name = "${var.environment}-${concat(var.aws_region, element(split(",", var.subnets), count.index))}"
    environment = "${var.environment}"
    project = "${var.project}"
    product = "${var.product}"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.environment} internet gateway"
    environment = "${var.environment}"
    project = "${var.project}"
    product = "${var.product}"
  }
}

# Create route table
resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "${var.environment} route table"
    environment = "${var.environment}"
    project = "${var.project}"
    product = "${var.product}"
  }
}

# Associate route table to subnets
resource "aws_route_table_association" "main" {
  count = "${var.amount_subnets}"
  subnet_id = "${element(aws_subnet.main.*.id, count.index)}"
  route_table_id = "${aws_route_table.main.id}"
}

# Replace the main route table with the created one
resource "aws_main_route_table_association" "main" {
    vpc_id = "${aws_vpc.main.id}"
    route_table_id = "${aws_route_table.main.id}"
}
