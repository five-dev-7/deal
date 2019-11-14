pragma solidity >=0.4.21 <0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./StorageLib.sol";

contract Deal {

    using SafeMath for uint256 ;
    mapping( bytes32 => Order ) public __orders ;       //防止枚举 k
    mapping( address => bytes32[] ) public __buyOrders ;
    mapping( address => bytes32[] ) public __sellOrders ;
    uint256 public __orderCount = 0 ;
    address _defaultAddress = 0x0000000000000000000000000000000000000000 ;
    uint __feeValue = 5 ; // fee = amount/1000*__feeValue ;
    uint256 __maxAmount = 10000 ether ;
    
    struct Order {
        uint256 index ;
        string title ;
        string content ;
        uint256 amount ;
        uint256 deposited ;
        uint256 fee ;
        address creator ;
        address buyer ;
        address seller ;
        uint8 state ;
        uint expireTime ;
        uint createTime ;
        uint lastTime ;
    }

    modifier isCreator( bytes32 orderId ) {
        Order memory order = __orders[ orderId ] ;
        require( msg.sender == order.creator , "not creator.") ;
        _ ;
    }

    modifier isBuyer( bytes32 orderId ) {
        Order memory order = __orders[ orderId ] ;
        require( msg.sender == order.buyer , "not buyer.") ;
        _ ;
    }

    modifier isSeller( bytes32 orderId ) {
        Order memory order = __orders[ orderId ] ;
        require( msg.sender == order.seller , "not seller.") ;
        _ ;
    }

    function makeOrderKey( address _creator , uint256 _index ) public pure returns (bytes32 _indexKey ){
        _indexKey = keccak256( abi.encodePacked( uint256( _creator) , _index )  ) ;
    } 

    event createOrderEvent( address _creator , bytes32 _orderNo ) ;

    function createOrder(string memory _title , string memory _content , bool _isBuyOrder , 
            uint256 _amount , uint exTime ) payable
        public returns (bytes32) {

        address _creator = msg.sender ;
        address _buyer = _defaultAddress ;
        address _seller = _defaultAddress ;
        uint256 _deposited = 0 ;
        uint256 _fee = 0 ;

        require( _amount > 0 && _amount <= __maxAmount , "Must be more than 0 ether and less than 10000 ether ." ) ;
        require( exTime > 1 , "Must be more than 1 hours .") ;

        __orderCount = __orderCount.add(1) ;
        bytes32 _orderKey = makeOrderKey( _creator , __orderCount ) ;
        if( _isBuyOrder == true ){
            _buyer = _creator ;
            require( msg.value > 0.001 ether , "must be more than 0.001 ether .") ;
            if( msg.value > 0.001 ether ) {
                _deposited = msg.value ;
            }
            __buyOrders[ _buyer ].push( _orderKey ) ;
        }else{
            _seller = _creator ;
            __buyOrders[ _seller ].push( _orderKey ) ;
        }

        _fee = _amount.div(1000).mul( __feeValue ) ;

        uint8 checkState = 0 ;
        if( _amount >= _deposited ){
            checkState = 1 ;
            if( _deposited > _amount ){
                uint256 rev = _deposited.sub( _amount ) ;
                msg.sender.transfer( rev ) ;        //transfer  .
            }
        }

        __orders[ _orderKey ] = Order({ 
            index : __orderCount ,
            title : _title ,
            content : _content ,
            amount : _amount ,
            deposited : _deposited ,
            fee : _fee ,
            creator : _creator ,
            buyer : _buyer ,
            seller : _seller ,
            state : checkState ,
            expireTime : now + ( exTime * 1 hours ) ,
            createTime : now ,
            lastTime : now 
        }); 
        emit createOrderEvent( _creator , _orderKey ) ;
        return _orderKey ;

    }

    function deposite(bytes32 _orderNo ) public payable isBuyer( _orderNo ) {
        Order storage order = __orders[  _orderNo ] ;
        
        require( order.state == 0 , "can't deposite." ) ;
        require( order.deposited < order.amount , "Already deposited." ) ;
        uint256 _trueAmt = order.amount - order.deposited ;
        if( msg.value > _trueAmt ){
            //有超出
            uint rev = msg.value.sub( _trueAmt ) ;
            msg.sender.transfer( rev ) ;
        }else{
            _trueAmt = msg.value ;
        }

        order.deposited = order.deposited.add( _trueAmt ) ;
        if( order.deposited == order.amount ){
            order.state = 1 ;   //update to payed .
        }

        order.lastTime = now ;

    }

    function cancelFromBuyer( bytes32 _orderNo ) public isBuyer( _orderNo ) {
        Order storage order = __orders[  _orderNo ] ;
        require( order.state <= 1 , "Can't cancel deal." ) ;
        if( order.deposited > 0 ) {
            address( uint160( order.buyer ) ).transfer( order.deposited ) ;
        }
        order.state = 5 ;
        order.lastTime = now ;
    }

    function cancelFromSeller( bytes32 _orderNo ) public isSeller( _orderNo ) {

        Order storage order = __orders[  _orderNo ] ;
        require( order.state <= 3 , "Can't cancel deal .") ;
        if( order.deposited > 0 ) {
            address( uint160( order.buyer ) ).transfer( order.deposited ) ;
        }
        order.state = 5 ;
        order.lastTime = now ;
    }

    function accept(bytes32 _orderNo ) public {
        Order storage order = __orders[  _orderNo ] ;
        require( order.creator != _defaultAddress , "no order." ) ;
        require( order.seller == _defaultAddress , "Already accept." ) ;
        order.seller = msg.sender ;
        order.lastTime = now ;
    }

    function deliver(bytes32 _orderNo ) public isSeller( _orderNo ) {

        Order storage order = __orders[  _orderNo ] ;
        require( order.state == 1 , "Must be deposited first ." ) ;
        order.state = 2 ;   //delivered.
        order.lastTime = now ;

    }

    function confirm( bytes32 _orderNo ) public isSeller( _orderNo ) {

        Order storage order = __orders[  _orderNo ] ;
        require( order.state == 2 , "Must be delivered first ." ) ;

        order.state = 4 ;   //delivered.
        order.lastTime = now ;

        //transfer to seller .
        convertPayableAddress( order.seller ).transfer( order.deposited ) ;
    }

    function convertPayableAddress( address addr ) internal returns ( address payable ){
        return address(uint160( addr )) ;
    }

    function queryBuyOrders( address _owner ) public view returns ( bytes32[] memory ) {
        return __buyOrders[ _owner ] ;
    }

}
