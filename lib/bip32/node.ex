defmodule Bip32.Node do
  defstruct [:private_key, :public_key, :public_key_uncompressed, :chain_code, :depth, :index, :parent, :curve_name]

  #curve_key = https://github.com/satoshilabs/slips/blob/master/slip-0010.md
  # https://bitcoin.org/img/dev/en-hd-root-keys.svg
  def generate_master_node(seed_hex, curve_name \\ :secp256k1, curve_key \\ "Bitcoin seed") do
    # hash the seed
    seed = Bip32.Utils.pack_h(seed_hex)
    one_way_hash = Bip32.Utils.hmac_sha512(curve_key, seed)

    # get the private key and chain code
    master_private_key_hex  = String.slice(one_way_hash, 0..63) # left is the private key
    master_chain_code_hex = String.slice(one_way_hash, 64..127) # right is the chain code

    # get the master public key from master private key
    master_public_key_hex = Bip32.Utils.get_public_key_from_private_key(master_private_key_hex, curve_name)
    master_public_key_hex_uncompressed = Bip32.Utils.get_public_key_from_private_key(master_private_key_hex, curve_name, :uncompressed)

    %Bip32.Node{
      private_key: master_private_key_hex, 
      public_key: master_public_key_hex, 
      public_key_uncompressed: master_public_key_hex_uncompressed, 
      chain_code: master_chain_code_hex,
      depth: 0,
      index: 0,
      curve_name: curve_name,
    }
  end

  def to_bip32(node, version_prv \\ "0488ade4", version_pub \\ "0488b21e") do
    depth = node.depth |> Integer.to_string(16) |> String.pad_leading(2, "0") |> String.downcase
    parent_key_fingerprint = ( if node.depth == 0, do: "00000000", else: Bip32.Utils.fingerprint(node.parent.public_key) )
    child_number = node.index |> Integer.to_string(16) |> String.pad_leading(8, "0") |> String.downcase

    xprv =
      case node.private_key do
        nil -> nil
        _ -> p_serialize(version_prv, depth, parent_key_fingerprint, child_number, node.chain_code, "00#{node.private_key}")
      end
    xpub = p_serialize(version_pub, depth, parent_key_fingerprint, child_number, node.chain_code, node.public_key)

    if xprv == nil do
      %{xpub: Bip32.Utils.checksum_base58(xpub)}
    else
      %{xpub: Bip32.Utils.checksum_base58(xpub), xprv: Bip32.Utils.checksum_base58(xprv)}
    end
    
  end

  def from_bip32(bip32, curve_name \\ :secp256k1) do
    decoded = "0" <> (Base58.decode(bip32) |> Integer.to_string(16))
    # checksum = String.slice(decoded, -8..-1)
    bip32 = String.slice(decoded, 0..-9) |> String.downcase

    # version = String.slice(bip32, 0..7)
    depth = String.slice(bip32, 8..9)
    # parent_key_fingerprint = String.slice(bip32, 10..17)
    child_number = String.slice(bip32, 18..25)
    chain_code = String.slice(bip32, 26..89)
    key = String.slice(bip32, 90..-1)

    {private_key, public_key} = if String.slice(key, 0..1) == "00" do
      private_key = String.slice(key, 2..-1)
      {private_key, Bip32.Utils.get_public_key_from_private_key(private_key, curve_name)}
    else
      {nil, key}
    end

    %Bip32.Node{
      private_key: private_key, 
      public_key: public_key, 
      chain_code: chain_code,
      depth: String.to_integer(depth, 16),
      index: String.to_integer(child_number, 16),
      curve_name: curve_name,
    }
  end

  defp p_serialize(version, depth, parent_key_fingerprint, child_number, chain_code, key_hex) do
    version <> depth <> parent_key_fingerprint <> child_number <> chain_code <> key_hex
  end

  @order String.to_integer("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141", 16)

  defp p_build_one_way_hash(private_key_hex, public_key_pub, chain_code_hex, i \\ 0)
  # hardened
  defp p_build_one_way_hash(nil, _, _, i) when i >= 0x80000000, do: raise "private key missing!"
  defp p_build_one_way_hash(private_key_hex, _, chain_code_hex, i) when i >= 0x80000000 do
    message = <<0>> <> Bip32.Utils.pack_h(private_key_hex) <> Bip32.Utils.i_as_bytes(i)
    Bip32.Utils.pack_h(chain_code_hex) |> Bip32.Utils.hmac_sha512(message)
  end
  # normal
  defp p_build_one_way_hash(_, public_key_pub, chain_code_hex, i) when i >= 0 and i < 0x80000000 do
    message = Bip32.Utils.pack_h(public_key_pub) <> Bip32.Utils.i_as_bytes(i)
    Bip32.Utils.pack_h(chain_code_hex) |> Bip32.Utils.hmac_sha512(message)
  end

  # https://bitcoin.org/img/dev/en-hd-private-parent-to-private-child.svg
  def derive_child(node, i \\ 0, only_public \\ false) do
    one_way_hash = p_build_one_way_hash(node.private_key, node.public_key, node.chain_code, i)
    
    # get the child private key
    left_int = one_way_hash |> String.slice(0..63) |> String.to_integer(16)
    child_private_key = rem (left_int + String.to_integer(node.private_key, 16)), @order
    child_private_key_hex = child_private_key |> Integer.to_string(16) |> String.downcase |> String.pad_leading(64, "0")

    # get the child chain code
    child_chain_code = one_way_hash |> String.slice(64..127) |> String.to_integer(16)
    child_chain_code_hex = child_chain_code |> Integer.to_string(16) |> String.downcase |> String.pad_leading(64, "0")

    # get the child public key
    child_public_key_hex = Bip32.Utils.get_public_key_from_private_key(child_private_key_hex, node.curve_name)
    child_public_key_hex_uncompressed = Bip32.Utils.get_public_key_from_private_key(child_private_key_hex, node.curve_name, :uncompressed)

    %Bip32.Node{
      private_key: (if only_public, do: nil, else: child_private_key_hex),
      public_key: child_public_key_hex,
      public_key_uncompressed: child_public_key_hex_uncompressed,
      chain_code: child_chain_code_hex,
      depth: node.depth + 1,
      index: i,
      curve_name: node.curve_name,
      parent: node,
    }
  end

  defp p_derive(node, [head | tail], only_public \\ false) do
    i = case String.ends_with?(head, "'") do
      true -> 0x80000000 + (head |> String.slice(0..-2) |> String.to_integer)
      false -> String.to_integer(head)
    end

    if length(tail) == 0 do
      derive_child(node, i, only_public)
    else
      derive_child(node, i, false) |> p_derive(tail, only_public)
    end
  end

  # 是否hardened由i决定；是否只是公钥派生，由m/M决定，而且只对最后一个节点有效
  def derive_descendant_by_path(node, path) do
    [head | tail] = String.split(path, "/")
    
    case head do
      "m" -> p_derive(node, tail)
      "M" -> p_derive(node, tail, true) # 只对最后一个节点有效
    end
    
  end

end