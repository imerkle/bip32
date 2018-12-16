defmodule Bip32.Utils do
  @moduledoc """
  Module of utils
  """

  def hmac_sha512(key, message) do
    :crypto.hmac(:sha512, key, message) |> Base.encode16(case: :lower)
  end

  def pack_h(hex) do
    hex = 
      case rem(String.length(hex), 2) do
        0 -> hex
        _ -> hex <> "0"
      end
    Base.decode16!(hex, case: :mixed)
  end

  def unpack_h(binary) do
    Base.encode16(binary, case: :lower)
  end

  def sha256(hex) do
    :crypto.hash(:sha256, Bip32.Utils.pack_h(hex)) |> unpack_h
  end

  def ripemd160(hex) do
    :crypto.hash(:ripemd160, Bip32.Utils.pack_h(hex)) |> unpack_h
  end

  def hash160(hex) do
    hex |> sha256 |> ripemd160
  end

  def checksum_base58(hex) do
    checksum = hex |> sha256 |> sha256 |> String.slice(0..7)
    address = hex <> checksum
    address_dec = String.to_integer(address, 16)
    Base58.encode(address_dec)
  end

  def decode_checksum_base58(base58) do
    Integer.to_string(Base58.decode(base58), 16)
    # checksum = String.slice(hex, -8..-1)
  end
  
  def fingerprint(public_key_hex) do
    hash = Bip32.Utils.hash160(public_key_hex)
    String.slice(hash, 0..7)
  end

  def get_public_key_from_private_key(private_key_hex, curve_name \\ :secp256k1, compression \\ :compressed) do

    priv = private_key_hex |> pack_h
    {pubkey, _p} = :crypto.generate_key(:ecdh, curve_name, priv)
    pubkey = if compression == :compressed do pubkey |> compress() else pubkey end
    unpack_h(pubkey)
  end
  
  #https://github.com/aeternity/elixir-wallet/blob/dfacf31f689c9c2b14e076ce97f889ac0a49f656/lib/aewallet/key_pair.ex#L358
  def compress(<<_prefix::size(8), x_coordinate::size(256), y_coordinate::size(256)>>) do
    prefix = case rem(y_coordinate, 2) do
      0 -> 0x02
      _ -> 0x03
    end
    <<prefix::size(8), x_coordinate::size(256)>>
  end
  
  # ruby: [i].pack('N')
  def i_as_bytes(i) do
    Integer.to_string(i, 16) |> String.pad_leading(8, "0") |> Base.decode16!(case: :upper)
  end
end