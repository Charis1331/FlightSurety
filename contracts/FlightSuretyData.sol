pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false
    mapping(address => bool) private registeredAirlines;
    mapping(address => uint256) private fundedAirlines;
    mapping(address => uint256) private authorizedContracts;
    address[] airlines;
    mapping(address => uint256) private accountBalance;
    //flightkey => passengers
    mapping(bytes32 => address[]) private airlineinsurees;
    //mapping(address =>mapping(bytes32 => Payment)) insuredamount;

    //passenger =>(flightkey => amount)
    mapping(address => mapping(bytes32 => uint256)) insuredamount;
    mapping(address => uint256) private fundedinsurance;

    //flightkey =>(passenger => payout)
    mapping(bytes32 => mapping(address => uint256)) insuredpayout;

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor(address firstAirline) public {
        contractOwner = msg.sender;
        registeredAirlines[firstAirline] = true;
        airlines.push(firstAirline);
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireIsCallerAirlineRegistered(address caller) {
        require(registeredAirlines[caller] == true, "Caller not registered");
        _;
    }

    modifier requireisAirlineNotRegistered(address airline) {
        require(
            registeredAirlines[airline] == false,
            "Airline already registered"
        );
        _;
    }
    modifier requireIsCallerAuthorized() {
        require(
            authorizedContracts[msg.sender] == 1,
            "Caller is not contract owner"
        );
        _;
    }

    /*modifier requireisAirlineFunded(address airline)
    {
        require( fundedAirlines[airline] >= 10, "Airline must submit funds of 10 ether");
        _;
    }*/
    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isnotinsured(
        address airline,
        string flight,
        uint256 timestamp,
        address passenger
    ) external view returns (bool) {
        bytes32 flightkey = getFlightKey(airline, flight, timestamp);
        uint256 amount = insuredamount[passenger][flightkey];
        return (amount == 0);
    }

    function isAirlineRegistered(address airline) public view returns (bool) {
        return registeredAirlines[airline];
    }

    /**
     * @dev airline can only take part in registration of other airlines
     *     if it has more than 10 ether in its balance
     */
    /* function isAirlineFunded(address airline)
                            public
                            view
                            returns (bool)
    {

        if(fundedAirlines[airline] >= MIN_FUNDING_AMOUNT)
            return true;
        else
            return false;
    } */
    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */

    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */

    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    function authorizeCaller(address contractAddress)
        external
        requireContractOwner
    {
        authorizedContracts[contractAddress] = 1;
    }

    function deauthorizeCaller(address contractAddress)
        external
        requireContractOwner
    {
        delete authorizedContracts[contractAddress];
    }

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */

    function registerAirline(address airline)
        external
        requireIsOperational
        requireIsCallerAuthorized
        requireisAirlineNotRegistered(airline)
        returns (bool success)
    {
        require(airline != address(0));
        registeredAirlines[airline] = true;
        airlines.push(airline);
        return registeredAirlines[airline];
    }

    function getAirlines() external view returns (address[] memory) {
        return airlines;
    }

    function getPassengerFunds(address passenger)
        external
        view
        returns (uint256)
    {
        return accountBalance[passenger];
    }

    function withdrawPassengerFunds(uint256 amount, address passenger)
        external
        requireIsOperational
        requireIsCallerAuthorized
        returns (uint256)
    {
        accountBalance[passenger] = accountBalance[passenger] - amount;
        passenger.transfer(amount);

        return accountBalance[passenger];
    }

    /**
     * @dev airline can deposit funds in any amount
     */
    function fundAirline(address airline, uint256 amount)
        external
        requireIsOperational
        requireIsCallerAuthorized
        requireIsCallerAirlineRegistered(airline)
    {
        fundedAirlines[airline] += amount;
    }

    /**
     * @dev to see how much fund an airline has
     */
    function getAirlineFunds(address airline)
        external
        view
        requireIsOperational
        requireIsCallerAuthorized
        requireIsCallerAirlineRegistered(airline)
        returns (uint256 funds)
    {
        return (fundedAirlines[airline]);
    }

    /**
     * @dev Buy insurance for a flight. If a passenger sends more than 1 ether then the excess is returned.
     *
     */

    function buy(
        address airline,
        string flight,
        uint256 _timestamp,
        address passenger,
        uint256 amount
    )
        external
        requireIsOperational
        requireIsCallerAuthorized
        requireIsCallerAirlineRegistered(airline)
    {
        bytes32 flightkey = getFlightKey(airline, flight, _timestamp);

        // PassengerInsurance memory pinsurance = PassengerInsurance({passenger:_passenger,insuranceamount:amount,payout:0});
        //airlineInsurance[flightkey].push(pinsurance);

        airlineinsurees[flightkey].push(passenger);

        insuredamount[passenger][flightkey] = amount;
        insuredpayout[flightkey][passenger] = 0;
    }

    uint256 public total = 0;

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees(
        address airline,
        string flight,
        uint256 timestamp,
        uint256 factor_numerator,
        uint256 factor_denominator
    ) external requireIsOperational requireIsCallerAuthorized {
        //get all the insurees
        bytes32 flightkey = getFlightKey(airline, flight, timestamp);

        address[] storage insurees = airlineinsurees[flightkey];

        for (uint8 i = 0; i < insurees.length; i++) {
            address passenger = insurees[i];
            uint256 payout;
            uint256 amount = insuredamount[passenger][flightkey];

            //check if already paid
            uint256 paid = insuredpayout[flightkey][passenger];
            if (paid == 0) {
                // bool success = _appcontract.call(bytes4(keccak256("calculatePayout(uint256)")), amount);
                payout = amount.mul(factor_numerator).div(factor_denominator);

                insuredpayout[flightkey][passenger] = payout;
                accountBalance[passenger] += payout;
            }
        }
    }

    //functions to debug contract
    /*  function getInsurees(address airline,string flight,uint ts) 
                        external
                         view
                         requireIsOperational
                        requireIsCallerAuthorized 
                        returns(PassengerInsurance[])
        {  
           
       // PassengerInsurance memory pinsurance
             bytes32 flightkey = getFlightKey(airline,flight,ts);
            PassengerInsurance[] storage insurees = airlineInsurance[flightkey];//airlineinsurees[flightkey];

            return insurees; 
        } */
    /*
         function isAmountNotPaid(address airline,string flight,uint ts,address passenger) 
                        external
                         view
                         requireIsOperational
                        requireIsCallerAuthorized 
                        returns(bool)
        {  
        
            bytes32 flightkey = getFlightKey(airline,flight,ts);
            uint paid = insuredpayout[flightkey][passenger];
            return (paid == 0); 
        } */

    function getAccountBalance(address passenger)
        external
        view
        requireIsOperational
        requireIsCallerAuthorized
        returns (uint256)
    {
        return accountBalance[passenger];
    }

    /*  function getInsuredAmount(address airline,string flight,uint ts,address passenger) 
                        external
                         view
                         requireIsOperational
                        requireIsCallerAuthorized 
                        returns(uint)
        {  
        
            bytes32 flightkey = getFlightKey(airline,flight,ts);
            uint amount = insuredamount[passenger][flightkey];
            return amount; 
        } */

    /* function getInsureesAmount(address airline,string flight,uint ts) external  returns(uint)
    {  
      
        bytes32 flightkey = getFlightKey(airline,flight,ts);
        address[] storage insurees = airlineinsurees[flightkey];
          for(uint8 i = 0; i < insurees.length; i++) {
                address passenger = insurees[i];
                
                total = total + accountBalance[passenger];
          }
          return total;
        
         
    } */
    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay(
        address airline,
        string flight,
        uint256 ts,
        address passenger,
        uint256 payout
    ) external requireIsOperational requireIsCallerAuthorized {
        bytes32 flightkey = getFlightKey(airline, flight, ts);
        insuredpayout[flightkey][passenger] = payout;
        accountBalance[passenger] += payout;

        //uint256 prev = accountBalance[customerAddress];
        //accountBalance[customerAddress] = 0;
        //passenger.transfer(payout);
    }

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */

    function fund() public payable {}

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    function() external payable {
        fund();
    }
}
