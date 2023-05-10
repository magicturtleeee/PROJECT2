// SPDX-License-Identifier: UNLICENSED
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Ticketing is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    constructor() ERC721("My NFT", "MNFT")  {}
    struct Ticket {
        uint256 tokenId;
        string tokenURI;
        uint256 ticketPrice;
        address ownerT;
        bool isRedeemed;
        uint256 showDate;
        string venue;
        string seatPosition;
        string typee; 
    }
    uint256 public totalTickets;
    uint256 public maxTickets = 1000;
    mapping (uint256 => Ticket) public tickets;

    function mintNFT(string[] memory tokenURI, uint256 _ticketPrice, uint256 _showDate, string memory _venue, string[] memory _seatPosition, string memory _typee) public returns (uint256[] memory) {
        require(totalTickets < maxTickets, "Maximum number of tickets already minted");
        require(msg.sender!=address(0));
        uint256[] memory tokenIds = new uint256[](tokenURI.length);
        for (uint i = 0; i < tokenURI.length; i++){
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _setTokenURI(newItemId, tokenURI[i]);
            _tokenIds.increment();
            tokenIds[i] = newItemId;
            uint256 ticketPrice = _ticketPrice * 1 ether;
            Ticket memory newTicket = Ticket(newItemId, tokenURI[i], ticketPrice, msg.sender, false, _showDate, _venue, _seatPosition[i], _typee);
            tickets[newItemId] = newTicket;
            totalTickets++;
        }
        return tokenIds;
    
    }
    function transferNFT(address  from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(from, tokenId), "transfer caller is not owner nor approved");
        Ticket storage ticket = tickets[tokenId];
        require(!ticket.isRedeemed, "Ticket has already been redeemed");
        ERC721.transferFrom(from, to, tokenId);
        ticket.ownerT = to;
    }
    mapping(uint256 => address) public buycontract;
    function pushtosale(uint256 tokenId) public {

        approve(address(this), tokenId);
        transferFrom(msg.sender,address(this), tokenId);
        buycontract[tokenId] = address(this);
        
    }
   
    function buyNFT(uint256 tokenId, address buy) public payable {
        Ticket storage ticket = tickets[tokenId];
        require(ticket.ownerT != msg.sender, "You already have this ticket");
        payable(ticket.ownerT).transfer(ticket.ticketPrice);
        ticket.ownerT = msg.sender;
         //Actually transfer the token to the new owner
        IERC721(buy).transferFrom(address(this), msg.sender, tokenId);
        //approve the marketplace to sell NFTs on your behalf
        ticket.ownerT = msg.sender;
    }

    function giftNFT(address to, uint256 tokenId, address buy) public payable {
        Ticket storage ticket = tickets[tokenId];
        require(ticket.ownerT != to, "The person already has this ticket");
        buyNFT(tokenId, buy);
        transferNFT(msg.sender, to, tokenId);
    }
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory _tokenURI = tokenURI(tokenId);
        return _tokenURI;
    }
        // Lottery 
    struct Lottery {
        address ownerL;
        address[] players;
        address winner;
        bool completed;
        uint256 id;
        uint256 lotteryId;
        uint256 priceL;
    }
    mapping(uint256 => Lottery) public lot;
    uint256 public lotterytickets;
    address public ownerL;
    uint256 public lotteryId =0;
    function lotteryforticket(uint256 tokenId, uint256 _price, uint256 _lotterytickets) public {
        Ticket storage ticket = tickets[tokenId];
        require(ticket.ownerT == msg.sender, "It is not your ticket");
        require(!ticket.isRedeemed, "Ticket has already been redeemed"); 
        address[] memory emptyArray;
        ownerL = msg.sender;
        uint256 price = _price * 1 ether;
        Lottery memory newLottery = Lottery(ownerL, emptyArray, address(0), false, tokenId, lotteryId, price);
        lotterytickets = _lotterytickets;
        lot[lotteryId] = newLottery;
        lotteryId++;
    }

    modifier onlyowner() {
        require(msg.sender == ownerL, "Only owner can use this function");
        _;
    }

    function enter(uint256 lotteryIdd) public payable returns (address[] memory) {
        Lottery storage lottery = lot[lotteryIdd];  

        // require at least price ether for entering
        require(msg.sender.balance >= lottery.priceL, "You don't have enough money");
        payable(ownerL).transfer(lottery.priceL);
        
        // require lottery is not over
        require(lottery.completed != true, "Sorry, lottery is over");

        require(lottery.players.length < lotterytickets, "All tickets are sold");

        for (uint i = 0; i < lottery.players.length; i++) {
            require(lottery.players[i]!= msg.sender, "You've already joined!");
        }
        lottery.players.push(msg.sender);
        return (lottery.players);
    }


    function getRandomNumber() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(ownerL, block.timestamp)));
    }
    function choosewinner(uint256 lotteryIdd) public onlyowner {
        Lottery storage lottery = lot[lotteryIdd];
        require(lottery.completed != true, "Sorry, lottery is over");
        uint index = getRandomNumber() % lottery.players.length;
        lottery.winner = lottery.players[index];
        lottery.completed = true;
        transferNFT(ownerL,lottery.winner,lottery.id);
        lottery.players = new address [](0);

    } 

}
