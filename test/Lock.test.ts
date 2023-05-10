import { ethers} from 'hardhat';
import { expect } from 'chai';
import { Contract, Signer } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { formatEther, parseEther } from 'ethers/lib/utils';

interface CustomSigner extends SignerWithAddress {}

describe('Ticketing', () => {
  let ticketing: Contract;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;

  it('should mint NFTs and transfer ownership', async () => {
    const Ticketing = await ethers.getContractFactory('Ticketing');
    [owner, addr1, addr2] = await ethers.getSigners();

    const ticketing = await Ticketing.deploy();
    await ticketing.deployed();
    const tokenURI = 'https://example.com/nft';
    const ticketPrice = 1;
    const showDate = 1234567890;
    const venue = 'Example Venue';
    const seatPosition = 'A1';
    const typee = 'General';

    await ticketing.connect(addr1).mintNFT(
      [tokenURI],
      ticketPrice,
      showDate,
      venue,
      [seatPosition],
      typee
    );

    const totalTickets = await ticketing.totalTickets();
    expect(totalTickets).to.equal(1);

    const ticket = await ticketing.tickets(0);
    expect(ticket.tokenURI).to.equal(tokenURI);
    expect(ticket.ticketPrice).to.equal(ethers.utils.parseEther('1'));
    expect(ticket.ownerT).to.equal(addr1.address);
    expect(ticket.isRedeemed).to.equal(false);
    expect(ticket.showDate).to.equal(showDate);
    expect(ticket.venue).to.equal(venue);
    expect(ticket.seatPosition).to.equal(seatPosition);
    expect(ticket.typee).to.equal(typee);

    await ticketing.connect(addr1).transferNFT(addr1.address, addr2.address, 0);

    const newTicketOwner = await ticketing.ownerOf(0);
    expect(newTicketOwner).to.equal(addr2.address);
  });

  // Add more test cases here

});
