pragma solidity >0.4.23 <0.7.0;

/**
 * @title The advantage of a blind auction is that there is no time pressure towards the end of the bidding period. 
 * Creating a blind auction on a transparent computing platform might sound like a contradiction, 
 * but cryptography comes to the rescue.
 * During the bidding period, a bidder does not actually send their bid, but only a hashed version of it. 
 * Since it is currently considered practically impossible to find two (sufficiently long) values whose hash values are equal, 
 * the bidder commits to the bid by that. After the end of the bidding period, the bidders have to reveal their bids: 
 * They send their values unencrypted and the contract checks that the hash value is the same as the one provided 
 * during the bidding period.
 * Another challenge is how to make the auction binding and blind at the same time: 
 * The only way to prevent the bidder from just not sending the money after they won the auction is 
 * to make them send it together with the bid. 
 * Since value transfers cannot be blinded in Ethereum, anyone can see the value.
 * The contract solves this problem by accepting any value that is larger than the highest bid. 
 * Since this can of course only be checked during the reveal phase, some bids might be invalid, 
 * and this is on purpose (it even provides an explicit flag to place invalid bids with high value transfers): 
 * Bidders can confuse competition by placing several high or low invalid bids.
 * 所谓盲拍，就是在一段时间内，所有参与者都可以出价，但是并不知道其他人出价的情况，
 * 在出价期结束后，揭晓所有人的出价，出价高者获胜 。 
 * 盲拍的关键是既要允许任何人都可以参加出价，而且出价必须同时付钱，又要让每个人的出价都只对自己可见，而其他人无法看到自己的出价 。 
 * 如果只是通过“叫价”（声明出多少钱而不付以太币）的形式进行出价，可以通过对出价进行加密，但这样的方式对出价者没有约束力，
 * 出价者完全可以在获胜之后拒绝付钱 。 
 * 但是以付钱的形式出价，转账的金额（Transaction 的 value 字段本身是公开的，无法禁止别人查看自己的出价。
 * 为了解决这一难题，合约引用了一种“混淆竞价”的方式：出价者可以在竞拍期提交假的出价，那么其他人虽然能看到此人每次的出价（转账的金额），
 * 但是不知道这次出价是真还是假，只有“真”出价会在最后生效，而“假”出价所付的金额在最后会被退回 。 
 * 而出价的“真”与“假”可以在出价时进行加密，在竞拍期结束后引人一个“揭晓期”，要求所有出价者揭晓每次出价的真假 。 
 */
contract BlindAuction {
    // 出价的数据结构
    struct Bid {
        bytes32 blindedBid; // 加密后的出价的真伪
        uint deposit; // 出价时所付的金额
    }
    
    // 拍卖的受益者 ， 将获取拍卖所得的以大币
    address payable public beneficiary;
    // 竞拍期结束的时间戳
    uint public biddingEnd;
    // 揭晓期结束的时间戳
    uint public revealEnd;
    bool public ended;
    
    // 各个出价者和其屡次出价的映射
    mapping(address => Bid[]) public bids;
    
    // 在揭晓每次出价后，当前出价最高者
    address public highestBidder;
    // 在揭晓每次出价后，当前的最高出价
    uint public highestBid;
    
    // 需要退回竞拍者的地址和钱款
    mapping(address => uint) public pendingWithdrawls;
    
    event AuctionEnded(address winner, uint highestBid);
    
    // 用来限制函数的执行时间在 time 时间戳之前
    modifier onlyBefore(uint _time) {require(now < _time); _;}
    // 用来限制函数的执行时间在 time 时间戳之后
    modifier onlyAfter(uint _time) {require(now > _time); _;}
    
    /**
     * @param _beneficiary 本次拍卖所得的受益者
     * @param _biddingTime 竞拍期的时长（以秒为单位）
     * @param _revealTime 竞拍期之后的揭晓期的时长（以秒为单位）
     */
    constructor (
        uint _biddingTime,
        uint _revealTime,
        address payable _beneficiary
        ) public {
        beneficiary = _beneficiary;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;    
        }
        
    
    /**
     * @dev Place a blinded bid with `_blindedBid` = keccak256(abi.encodePacked(value, fake, secret)).
     * The sent ether is only refunded if the bid is correctly revealed in the revealing phase. 
     * The bid is valid if the ether sent together with the bid is at least "value" and "fake" is not true. 
     * Setting "fake" to true and sending not the exact amount are ways to hide the real bid but still make the required deposit. 
     * The same address can place multiple bids.
     * 出价函数，只能在竞拍期结束之前调用
     * @param _blindedBid 此参数是由 实际出价金额、本次出价的“真伪”、出价者生成的一个密钥 三者取散列生成的
     * 这个参数有两个作用： 一是隐含本次出价真伪的信息； 二是用以在揭晓期验证用户所揭晓的实际出价信息是否可信
     * deposit 出价者此次调用所付的以太币数量（ msg.value），可以理解为此次出价的押金 。 
     * 无论本次出价行为是真还是假，desposit并不代表实际出价的价格数值，理论上只要大于实际出价数值即可
     */
    function bid(bytes32 _blindedBid) public payable onlyBefore(biddingEnd) {
        bids[msg.sender].push(Bid({
            blindedBid: _blindedBid,
            deposit: msg.value
        }));
    }
    
    /**
     * @dev Reveal your blinded bids. 
     * You will get a refund for all correctly blinded invalid bids and for all bids except for the totally highest.
     * 揭晓函数，用来揭晓每次出价的 ” 真伪 ” 。 只能在竞拍期结束后 ， 揭晓期结束前
     * 在竞拍结束后，每个出价者都需要在揭晓期执行 reveal 函数，揭晓自己每次出价的详细信息
     * @param _values 每次出价的实际金额
     * @param _fake 每次出价行为的 “真伪”
     * @param _secret 对应的密钥
     * 每个数组元素按照对应的出价顺序进行排序
     */ 
    function reveal(
        uint[] memory _values,
        bool[] memory _fake,
        bytes32[] memory _secret
        ) 
        public
        onlyBefore(biddingEnd)
        onlyAfter(revealEnd)
        {
            // 需要判断用户指定的数组参数的长度 ，和记录在 bids 中的出价次数是否一致
            uint length = bids[msg.sender].length;
            require(_values.length == length);
            require(_fake.length == length);
            require(_secret.length == length);
            
            // 按照出价的先后顺序，依次揭晓每次出价
            uint refund;
            for (uint i = 0; i < length; i++){
                Bid storage bidToCheck = bids[msg.sender][i];
                (uint value, bool fake, bytes32 secret) = (_values[i], _fake[i], _secret[i]);
                // 对于每次出价 bid ，根据用户指定的三个参数求散列值： keccak256(value , fake, secret），
                // 判断这个散列值是否和被记录在合约中的相等
                if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
                    // Bid was not actually revealed.
                    // Do not refund deposit.
                    continue;
                }
                // 函数先把这次出价时所付的金额deposit先叠加到 refund 中，等待函数执行结束前退款。 
                // 对于“伪” 出价，直接等待退款即可；
                // 对于“真”出价，还要先判断该次出价的所付钱是否大于用户的真实出价：
                // 如果否，意味着付的钱不够出价的金额，这次出价的钱还是会被退回 ；
                // 如果是，那么用户付的钱足够支付出价的金额， 此次出价成功 。 
                // 当判断出价成功后，调用内置函数placeBid ，查看该出价是否是最高出价，只有其返回 true ，
                // 才认为此次出价是最高出价，出价得以生效 。 
                // 这时需要在应退金额 refund 中去除该次出价的真实金额。
                // 也就是说， 当竞拍者实际付的金额（ deposit）大于其声称的实际出价(value ），
                // 多余的金额也会被退回给竞拍者，合约只会收取声称的实际出价。 
                // 虽然竞拍者在揭晓期才公布自己的 出价， 由于 blindedBid 的校验功能，竞拍者也不能篡改自己当时的出价数值
                refund += bidToCheck.deposit;
                if (!fake && bidToCheck.deposit >= value) {
                    if (placeBid(msg.sender, value)) {
                        refund -= value;
                    }
                }
                // Make it impossible for the sender to re-claim the same deposit.
                // 以此来证明此次出价已被揭晓过，否则一次出价可以被多次揭晓，每次都可以得到退款，这会存在严重漏洞 。 
                bidToCheck.blindedBid = bytes32(0);
            }
        // 依次揭晓各个出价后，竞拍者可以退回记录refund中的金额。 但这不意味着竞拍者已经退回了所有该退的钱 。 
        // 当一个竞拍者的出价成为最高出价后，又被自己后来的出价或者别人的出价超过时，这笔金额会被记录在 pendingWithdrawls 中 。 
        // 因此在竞拍全部结束后，每个竞拍者还应该再次调用 withdraw函数撤回自己应退的金额
        msg.sender.transfer(refund);
        }
        
    /// Withdraw a bid that was overbid
    /// 退款函数
    function withdraw() public {
        uint amount = pendingWithdrawls[msg.sender];
        if (amount > 0) {
            pendingWithdrawls[msg.sender] = 0;
       }
        msg.sender.transfer(amount);   
    }
    
    /// End the auction and send the highest bid to the beneficiary.
    /// 竞拍结束后执行 ， 将最高的出价支付给受益者
    /// 在揭晓期过后任何人都可以调用，用以给盲拍受益者发送最高的出价金额 。 
    /// 这个函数任何人都可以调用，但只能完整地执行一次
    function auctionEnd() public onlyAfter(revealEnd) {
        require(!ended);
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }
    
    /// 更新当前的最高出价，被 reveal 函数调用
    function placeBid(address bidder, uint value) internal returns (bool success) {
        if (value <= highestBid) {
            return false;
        }
        
        if (bidder != address(0)) {
            pendingWithdrawls[highestBidder] += highestBid;
            highestBidder = bidder;
            highestBid = value;
            return true;
        }
    }
}
