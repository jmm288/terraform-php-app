variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "PhpAppServer"
}

variable "az_number" {
  # Assign a number to each AZ letter used in our configuration
  default = {
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
    f = 6
  }
}
