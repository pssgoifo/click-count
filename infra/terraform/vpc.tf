#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "clickcount" {
  cidr_block = "10.0.0.0/16"

  tags = map(
    "Name", "terraform-eks-clickcount-node",
    "kubernetes.io/cluster/${var.cluster-name}", "shared",
  )
}

resource "aws_subnet" "clickcount" {
  count = 2

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.clickcount.id

  tags = map(
    "Name", "terraform-eks-clickcount-node",
    "kubernetes.io/cluster/${var.cluster-name}", "shared",
  )
}

resource "aws_internet_gateway" "clickcount" {
  vpc_id = aws_vpc.clickcount.id

  tags = {
    Name = "terraform-eks-clickcount"
  }
}

resource "aws_route_table" "clickcount" {
  vpc_id = aws_vpc.clickcount.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.clickcount.id
  }
}

resource "aws_route_table_association" "clickcount" {
  count = 2

  subnet_id      = aws_subnet.clickcount.*.id[count.index]
  route_table_id = aws_route_table.clickcount.id
}
