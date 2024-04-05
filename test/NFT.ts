import hre from "hardhat";
import "@nomicfoundation/hardhat-ethers";
import { expect } from "chai";

describe("NFT", () => {
  async function deployNFTFixture() {
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const NFT = await hre.ethers.getContractFactory("NFT");
    const nft = await NFT.deploy();

    return { nft, owner, otherAccount };
  }

  it("should allow minting with valid signature", async () => {
    const { nft, owner, otherAccount } = await deployNFTFixture();

    const quantity = 3;
    const nonce = hre.ethers.keccak256(hre.ethers.toUtf8Bytes("testNonce"));

    // Generate signature for the given data
    const messageHash = hre.ethers.solidityPackedKeccak256(
      ["uint256", "address", "bytes32"],
      [quantity, await otherAccount.getAddress(), nonce]
    );

    const signature = await owner.signMessage(
      hre.ethers.toBeArray(messageHash)
    );

    // Perform signed mint
    await nft.connect(otherAccount).signedMint(quantity, signature, nonce);

    // Check if balance of owner has increased
    expect(await nft.balanceOf(await otherAccount.getAddress())).to.equal(
      quantity
    );
  });

  it("should reject minting with invalid signature", async () => {
    const { nft, owner, otherAccount } = await deployNFTFixture();

    const quantity = 1;
    const nonce = hre.ethers.keccak256(hre.ethers.toUtf8Bytes("testNonce"));

    // Generate signature for the given data
    const messageHash = hre.ethers.solidityPackedKeccak256(
      ["uint256", "address", "bytes32"],
      [quantity, await otherAccount.getAddress(), nonce]
    );

    const signature = await owner.signMessage(
      hre.ethers.toBeArray(messageHash)
    );

    // Perform signed mint with signature from a different address
    await expect(nft.signedMint(quantity, signature, nonce)).to.be.revertedWith(
      "Invalid signature"
    );
  });

  it("should reject minting with already used signature", async () => {
    const { nft, owner, otherAccount } = await deployNFTFixture();

    const quantity = 1;
    const nonce = hre.ethers.keccak256(hre.ethers.toUtf8Bytes("testNonce"));

    // Generate signature for the given data
    const messageHash = hre.ethers.solidityPackedKeccak256(
      ["uint256", "address", "bytes32"],
      [quantity, await otherAccount.getAddress(), nonce]
    );

    const signature = await owner.signMessage(
      hre.ethers.toBeArray(messageHash)
    );

    // Perform signed mint with valid signature
    await nft.connect(otherAccount).signedMint(quantity, signature, nonce);

    // Attempt to use the same signature again
    await expect(
      nft.connect(otherAccount).signedMint(quantity, signature, nonce)
    ).to.be.revertedWith("Signature already used");
  });

  it("should not allow minting more than the maximum per wallet", async () => {
    const { nft } = await deployNFTFixture();
    const quantity = 4;

    // Attempt to mint tokens exceeding maximum per wallet
    await expect(
      nft.mint(quantity, { value: hre.ethers.parseEther("0.04") })
    ).to.be.revertedWith("Invalid mint quantity.");
  });

  it("should mint a set of tokens", async () => {
    const { nft, otherAccount } = await deployNFTFixture();
    // Mint set of tokens
    await nft
      .connect(otherAccount)
      .mintSet({ value: hre.ethers.parseEther("0.02") });

    // Check if balance of owner has increased by SET_AMOUNT
    expect(await nft.balanceOf(await otherAccount.getAddress())).to.equal(6);
  });

  it("should reject minting a set if already owns tokens", async () => {
    const { nft, otherAccount } = await deployNFTFixture();
    const quantity = 3;

    // Mint tokens
    await nft.connect(otherAccount).mint(quantity, {
      value: hre.ethers.parseEther("0.03"),
    });

    // Attempt to mint set when already owns tokens
    await expect(
      nft
        .connect(otherAccount)
        .mintSet({ value: hre.ethers.parseEther("0.02") })
    ).to.be.revertedWith("You can't mint set (limit exceeded).");
  });

  it("should allow withdrawing contract balance by owner", async () => {
    const { nft, owner } = await deployNFTFixture();
    // Mint tokens
    await nft.mint(1, { value: hre.ethers.parseEther("0.01") });

    // Withdraw contract balance
    await expect(nft.connect(owner).withdraw()).to.not.be.reverted;
  });

  it("should reject withdrawing contract balance by non-owner", async () => {
    const { nft, otherAccount } = await deployNFTFixture();
    // Attempt to withdraw contract balance by non-owner
    await expect(nft.connect(otherAccount).withdraw()).to.be.revertedWith(
      "Ownable: caller is not the owner"
    );
  });
});
