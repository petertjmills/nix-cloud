# Function that takes a subnet and returns a new function
subnet:
let
  # Split the subnet into address and prefix parts
  parts = builtins.split "/" subnet;
  address = builtins.elemAt parts 0;
  prefix = builtins.fromJSON (builtins.elemAt parts 2);

  # Split IP address into octets
  octets = builtins.split "[.]" address;

  # Convert IP to integer
  ipToInt =
    let
      oct0 = builtins.fromJSON (builtins.elemAt octets 0);
      oct1 = builtins.fromJSON (builtins.elemAt octets 2);
      oct2 = builtins.fromJSON (builtins.elemAt octets 4);
      oct3 = builtins.fromJSON (builtins.elemAt octets 6);
    in
    (oct0 * 16777216) + (oct1 * 65536) + (oct2 * 256) + oct3;

  # Calculate subnet size (total addresses)
  subnetSize =
    let
      exp = 32 - prefix;
      # Manually calculate 2^exp
      power = builtins.foldl' (x: y: x * 2) 1 (builtins.genList (x: x) exp);
    in
    power;

  # Calculate network address (floor to subnet boundary)
  network =
    let
      # Integer division by subnet size then multiply back
      factor = ipToInt / subnetSize;
    in
    factor * subnetSize;

  # Calculate broadcast address
  # broadcast = network + subnetSize - 1;

  # Function to convert integer back to IP string
  intToIp =
    int:
    let
      oct0 = int / 16777216;
      remaining1 = int - (oct0 * 16777216);
      oct1 = remaining1 / 65536;
      remaining2 = remaining1 - (oct1 * 65536);
      oct2 = remaining2 / 256;
      oct3 = remaining2 - (oct2 * 256);
    in
    "${toString oct0}.${toString oct1}.${toString oct2}.${toString oct3}";

in
# Return a function that converts an index to an IP in the subnet
index:
# let
# Calculate total addresses in range
# totalAddresses = subnetSize;
# in
# Throw error if index is out of range
# if !builtins.isInt index then
#   throw "Index must be an integer, got ${builtins.typeOf index}"
# else if index < 0 then
#   throw "Index must be non-negative, got ${builtins.toString index}"
# else if index >= totalAddresses then
#   throw "Index out of range. Must be less than ${builtins.toString totalAddresses}, got ${builtins.toString index}"
# else
# let
# Convert index to actual IP address
# resultIp = intToIp (network + index);
# in
{
  # Return the IP address for this index
  address = intToIp (network + index);

  # Return whether this is the network address (index 0)
  isNetworkAddress = index == 0;

  # Return whether this is the broadcast address (last index)
  isBroadcastAddress = index == (subnetSize - 1);

  # Return whether this is a usable address (not network or broadcast)
  isUsable = !(index == 0 || index == (subnetSize - 1));

  # Return the index
  index = index;

  # Return total available addresses in subnet
  totalAddresses = subnetSize;
}
