resource "yandex_vpc_route_table" "route_table" {
  name       = "nat"
  network_id = var.network_id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = var.next_hop_address
  }
}