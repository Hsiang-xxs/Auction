pragma solidity >=0.4.22 <0.7.0;


/**
 * @title Everyone can send their bids during a bidding period.
 * The bids already include sending money / Ether in order to bind the bidders to their bid. 
 * If the highest bid is raised,the previously highest bidder gets their money back. 
 * After the end of the bidding period, the contract has to be called 
 * manually for the beneficiary to receive their money - contracts cannot activate themselves.
 * 需要竞拍者在出价时直接把“钱”（以太币）发送给智能合约进行托管，否则只出价不付款，
 * 在拍卖结束后无法保证最高出价者能及时地按照拍卖价进行付款。
 * 此合约只用来管理拍卖的过程，负责拍卖的款项交割，而实际拍卖的物品并不在合约管理范围之内。
 * 合约的执行结果可以作为拍卖品所有权转移的依据，而不是保障。 
 */
contract OpenAuction{
    // 最终受益者
    address payable public beneficiary;
    
    // Times are either absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.
    // 拍卖结束的时间戳（精确到秒）
    uint public auctionEndTime;
    
    // Current state of auction.
    // 当前出价最高者
    address public highestBidder;
    // 当前最高的出价
    uint public highestBid;
    
    // Allowed withdrawls of previous bids.
    // 需要退回竞拍者和其出价
    mapping(address => uint) public pendingReturns;
    
    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    // 竞拍是否结束的标识符
    bool public ended;
    
    // 出现更高出价时引发的事件
    event HighestBidIncreased(address bidder, uint amount);
    // 竞拍结束时引发的事件
    event AuctionEnded(address winner, uint amount);
    
    /**
     * @dev Create a simple auction with `_biddingTime` seconds bidding time 
     * on behalf of the beneficiary address `_beneficiary`.
     * 初始化竞拍合约，指定竞拍期时间和最终受益者
     * 而拍卖结束的时间即为合约部署的时间（now 函数的返回值）加上竞拍时长
     */
    constructor (
        address payable _beneficiary,
        uint _biddingTime
    ) public {
        beneficiary = _beneficiary;
        auctionEndTime = now + _biddingTime;
    }
    
    /**
     * @dev Bid on the auction with the value sent together with this transaction.
     * The value will only be refunded if the auction is not won.
     * 竞拍者出价：所有人都可以调用合约的此函数进行出价
     */
    function bid() public payable {
        // Revert the call if the bidding period is over.
        // 根据当前的时间戳判断是否本次调用还在竞拍期内
        require(now <= auctionEndTime, "Auction already ended.");
        
        // If the bid is not higher, send the money back.
        // 根据 msg.value 判断此次出价是否高于之前的最高出价
        require(msg.value > highestBid, "There already is a higher bid.");
        
        // 之前最高出价以及出价者会被记录在公共变量pendingReturns中，留作退款依据
        if (highestBid != 0) {
            //Let the recipients withdraw their money themselves.
            pendingReturns[highestBidder] += highestBid;
        }
        
        // 用本次的出价 msg.value 和出价者 msg.sender 更新当前的最高出价 highestBid 和出价者 highestBidder
        highestBidder = msg.sender;
        highestBid = msg.value;
        
        // 记录下本次竞拍价格新高的事件
        emit HighestBidIncreased(msg.sender, msg.value);
    }
    
    /// 出价被别人超过后竞拍者可以执行撤销
    /// 当用户的出价被别人的出价超过，用户可以通过调用此函数让合约进行退款
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            
            if (!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
            return true;
        }
    }
    
    /// End the auction and send the highest bid to the beneficiary.
    /// 竞拍结束后执行 ， 将最高的出价支付给受益者
    function auctionEnd() public {
        // 判断竞拍期是否已经结束了
        require(now >= auctionEndTime, "Auction not yet ended.");
        // 判断竞拍本身已经结束 
        require(!ended, "auctionEnd has already been called.");
        
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        
        beneficiary.transfer(highestBid);
    }
}
