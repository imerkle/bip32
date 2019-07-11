defmodule Bip32Test do
  use ExUnit.Case
  doctest Bip32
"""
  test "generete master node from hex seed" do
    node = Bip32.Node.generate_master_node("6411fc4e712edf19a06bc5")

    assert node.private_key == "019501a2dcd7b5450388df7e3b426a5422c3570425296f206fecee56f332c079"
    assert node.public_key  == "02962f81719ca3de1c431c15af996bb9558b1790d8031cbfe702276fb754d44d33"
    assert node.chain_code  == "a386d620fc62c7a6a4ed83a19a0638c54c1486d8d8a60bfeeacac1b7a2e2e911"
    assert node.depth       == 0
    assert node.index       == 0
  end

  test "to bip32" do
    node = Bip32.Node.generate_master_node("6411fc4e712edf19a06bc5")

    bip32 = Bip32.Node.to_bip32(node)
    assert bip32.xprv == "xprv9s21ZrQH143K3gnXBZCcM9RAqTSzcEn6jK321gwpdN5XYR9i8m7WhRyuWTHgoNJDjVq9TgCQHgs5j875ZCPXVTrpkQwzdtTPUDPitoxJ4t5"
    assert bip32.xpub == "xpub661MyMwAqRbcGArzHajciHMuPVHV1hVx6Xxcp5MSBhcWRDUrgJRmFEJPMjSu7tXdzwvxrFojYP8oYne1X9Y4xWgyfWD3thLxpa3NEnPsMG8"
  end

  test "from bip32 xprv" do
    bip32 = "xprv9s21ZrQH143K3gnXBZCcM9RAqTSzcEn6jK321gwpdN5XYR9i8m7WhRyuWTHgoNJDjVq9TgCQHgs5j875ZCPXVTrpkQwzdtTPUDPitoxJ4t5"
    node = Bip32.Node.from_bip32(bip32)

    assert node.private_key == "019501a2dcd7b5450388df7e3b426a5422c3570425296f206fecee56f332c079"
    assert node.public_key  == "02962f81719ca3de1c431c15af996bb9558b1790d8031cbfe702276fb754d44d33"
    assert node.chain_code  == "a386d620fc62c7a6a4ed83a19a0638c54c1486d8d8a60bfeeacac1b7a2e2e911"
    assert node.depth       == 0
    assert node.index       == 0
  end

  test "from bip32 xpub" do
    bip32 = "xpub661MyMwAqRbcGArzHajciHMuPVHV1hVx6Xxcp5MSBhcWRDUrgJRmFEJPMjSu7tXdzwvxrFojYP8oYne1X9Y4xWgyfWD3thLxpa3NEnPsMG8"
    node = Bip32.Node.from_bip32(bip32)

    assert node.private_key == nil
    assert node.public_key  == "02962f81719ca3de1c431c15af996bb9558b1790d8031cbfe702276fb754d44d33"
    assert node.chain_code  == "a386d620fc62c7a6a4ed83a19a0638c54c1486d8d8a60bfeeacac1b7a2e2e911"
    assert node.depth       == 0
    assert node.index       == 0
  end

  test "derive child node" do
    node = Bip32.Node.generate_master_node("6411fc4e712edf19a06bc5")
    child_node = Bip32.Node.derive_child(node, 5)

    assert child_node.private_key == "4ff08af436785a6de1bdea489342a84a0c6d79caef43140375c1ef220c29bc4c"
    assert child_node.public_key  == "0207ad96a500055f694c57637897018e771e25af129ad89aacc1b7ea900fb232a1"
    assert child_node.chain_code  == "5408be244f01d7ba9900b9d65159e011c128cf067f3281a65e61ca1fb7f5edb2"
    assert child_node.depth       == 1
    assert child_node.index       == 5
  end

  test "derive by path" do
    node = Bip32.Node.generate_master_node("6411fc4e712edf19a06bc5")
    descendant_node = Bip32.Node.derive_descendant_by_path(node, "m/0/3")

    assert descendant_node.private_key == "cb1eaadc10a67bede79b87c444329c0c695d65c0992411d473481693cf13e0c7"
    assert descendant_node.public_key  == "03e63af50ed21b5eeb3a073d8653209fdc841274448ad953f4a67de9d0c264a0d3"
    assert descendant_node.chain_code  == "8139ac2c9c2d6414dc3679fe26a176ea2cbaa5cb8c7997021c954e35668bd9c3"
    assert descendant_node.depth       == 2
    assert descendant_node.index       == 3
  end

  test "hardered derive by path" do
    node = Bip32.Node.generate_master_node("6411fc4e712edf19a06bc5")
    descendant_node = Bip32.Node.derive_descendant_by_path(node, "m/0'/3")

    assert descendant_node.private_key == "9d87b03846ee0dd07f6ec026844807ee2b7ca6a4e4c778022cbaa855da8cf429"
    assert descendant_node.public_key  == "0256a8bca0b4fdfc860623fb971b87101124bd51d17143549efbebc5cfd16c5432"
    assert descendant_node.chain_code  == "69d9af470f341cdbf12a566de11b5bc7842c5f61a5a855bcaa839a5da80be09d"
    assert descendant_node.depth       == 2
    assert descendant_node.index       == 3
  end

  test "hardered derive by path 2" do
    node = Bip32.Node.generate_master_node("6411fc4e712edf19a06bc5")
    descendant_node = Bip32.Node.derive_descendant_by_path(node, "m/0'/3'")

    assert descendant_node.private_key == "dd5fb7ef0e6edf6c6021ea2f6c17ef0f136ab6d0313262e892e8e5e4e94fe1a6"
    assert descendant_node.public_key  == "022e6ae29b35231552665301812a9effb94b97f911ce0244d63b168e70112592cf"
    assert descendant_node.chain_code  == "3c54dc2ae89d7dd91b543008abbebf7bcd2a0e3a669bfc41a8bb0467dd2b97bb"
    assert descendant_node.depth       == 2
    assert descendant_node.index       == 2147483651
  end

  test "hardened derive without private key" do
    bip32 = "xpub661MyMwAqRbcGArzHajciHMuPVHV1hVx6Xxcp5MSBhcWRDUrgJRmFEJPMjSu7tXdzwvxrFojYP8oYne1X9Y4xWgyfWD3thLxpa3NEnPsMG8"
    node = Bip32.Node.from_bip32(bip32)

    assert node.private_key == nil
    try do
      Bip32.Node.derive_descendant_by_path(node, "m/0'")
    rescue
      e in RuntimeError -> assert e.message == "private key missing!"
    end

  end

  test "public key only derive" do
    node = Bip32.Node.generate_master_node("6411fc4e712edf19a06bc5")
    descendant_node = Bip32.Node.derive_descendant_by_path(node, "M/0'/3'")

    assert descendant_node.private_key == nil
    assert descendant_node.public_key  == "022e6ae29b35231552665301812a9effb94b97f911ce0244d63b168e70112592cf"
    assert descendant_node.chain_code  == "3c54dc2ae89d7dd91b543008abbebf7bcd2a0e3a669bfc41a8bb0467dd2b97bb"
    assert descendant_node.depth       == 2
    assert descendant_node.index       == 2147483651
  end

  test "secp256r1 derive" do
    node = Bip32.Node.generate_master_node("27a718f64d256afa9d95a1d561f059f8a2488c87b2ff56eaeee1ff8dac465804a54400f70205ee698c1b3e2cad4c5b8117f892878dea6d585c6db7e42ab3dda1", :secp256r1, "Nist256p1 seed")
    IO.inspect node.private_key
    descendant_node = Bip32.Node.derive_descendant_by_path(node, "m/44'/888'/0'/0/0")
    assert node.private_key == "4cd77b2ce020967696658e8817f6b693a453c76f7ee295c8d8b9c5de7e97966e"
    assert descendant_node.index == 0
    assert descendant_node.depth == 5
    assert descendant_node.curve_name == :secp256r1
    assert descendant_node.chain_code == "fc55225873440c25c393fe1f149718d37b85098b46ae3dda276eae6444f1612a"
    assert descendant_node.private_key == "1060eeb4ed10c63680cf9570fc7c5fa2c9d911f33f60f379ce7107f2618e9651"
    assert descendant_node.public_key == "03f7f87c8988579de62bd416958e8c27da8e7948a2639c1027eb37e386f10badcf"
  end

  """
  test "secp256k1 derive" do
    node = Bip32.Node.generate_master_node("27a718f64d256afa9d95a1d561f059f8a2488c87b2ff56eaeee1ff8dac465804a54400f70205ee698c1b3e2cad4c5b8117f892878dea6d585c6db7e42ab3dda1")
    assert node.private_key == node.public_key
    """
    descendant_node = Bip32.Node.derive_descendant_by_path(node, "m/44'/888'/0'/0/0")
    assert node.private_key == "4cd77b2ce020967696658e8817f6b693a453c76f7ee295c8d8b9c5de7e97966e"
    assert descendant_node.index == 0
    assert descendant_node.depth == 5
    assert descendant_node.curve_name == :secp256r1
    assert descendant_node.chain_code == "fc55225873440c25c393fe1f149718d37b85098b46ae3dda276eae6444f1612a"
    assert descendant_node.private_key == "1060eeb4ed10c63680cf9570fc7c5fa2c9d911f33f60f379ce7107f2618e9651"
    assert descendant_node.public_key == "03f7f87c8988579de62bd416958e8c27da8e7948a2639c1027eb37e386f10badcf"
    """
  end
end
