//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import 'hardhat/console.sol';

contract VanityName is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    /**
     * @dev An instance of ERC20 AcceptToken Token
     */
    IERC20 AcceptToken;
    
    /**
     * @dev info for name
     */
    struct VanityNameStruct {
        address _address;
        uint256 expiredAt;
    }

    /**
     * @dev address to receive the fee
     */
    address feeCollector;

    /**
     * @dev Mapping of name and VanityNameStruct
     */
    mapping(string => VanityNameStruct) private registry;

    /**
     * @dev Mapping of address and blance
     */
    mapping(address => uint256) private userBalances;

    /**
     * @dev Mapping of address and name
     */
    mapping(address => string) private names;

    /**
     * @dev Log when a name is registered
     * @param name  new vanity name
     * @param _vanityName VanityName construct
     */
    event NameRegistered(string indexed name, VanityNameStruct _vanityName);

    /**
     *  @dev Log when withdraw the fund.
     *  @param treasure sender address
     *  @param receiver withdrawer address
     *  @param fund fund amount
     */
    event Withdraw(address treasure, address receiver, uint256 fund);

    /**
     *  @dev Log when renew registration.
     *  @param register register address
     *  @param period duration for new rerigistartion
     */
    event RenewRegistration(address register, uint256 period);

    /**
     * @dev duration that can be registered(per token)
     */
    uint256 public millisecondsPer100Token;

    /**
     * @dev fee to register the name(per letter)
     */
    uint256 public feePerLetter; // 0.0025 1 token
    
    /**
     * @param _acceptToken the address of the deployed ERC20 AcceptToken
     * @param _feeCollector the address to store the fee
     */
    function __VanityName_init(address _acceptToken, address _feeCollector) public initializer {
        __Ownable_init();
        AcceptToken = IERC20(_acceptToken);
        feeCollector = _feeCollector;
        millisecondsPer100Token = 1;
        feePerLetter = 10 ** 18;
    }

    /**
     *  @dev Check whether a name is registered or not.
     *  @param name - Name string to check for existence
     */
    function nameExists(string memory name) internal view returns(bool) {
        return registry[name]._address != address(0);
    }

    /**
     *  @dev Returns amount of tokens to be used for name registration.
     *  @param name - Name string to calculate the fee
     */
    function getFee(string memory name) public view returns(uint256) {
        return bytes(name).length * feePerLetter;
    }

    /**
     *  Registers a new name.
     *  If the name already exists or caller's fund is not enough, caller cannot register.
     *  @param fund - Amount of tokens to be used for name registration
     */
    function getPeriod(uint256 fund) public view returns (uint256) {
        uint256 period = millisecondsPer100Token * (fund / (100 * 10 ** 18));
        if(millisecondsPer100Token > period) return 0;
        return period;
    }

    /**
     *  Registers a new name.
     *  If the name already exists or caller's fund is not enough, caller cannot register.
     *  @param name - Name to be registered
     *  @param fund - Amount of tokens to be used for name registration
     */
    function registerName(string memory name, uint256 fund) public {

        require(!nameExists(name), "name already registered");

        uint256 period = getPeriod(fund);
        require(period > 0, "Invalid period");
        uint256 fee = getFee(name);
        require(AcceptToken.balanceOf(msg.sender) >= fund + fee, "Insufficient fund");
        AcceptToken.transferFrom(msg.sender, address(this), fund);
        AcceptToken.transferFrom(msg.sender, feeCollector, fee);
        userBalances[msg.sender] = fund;
        names[msg.sender] = name;
        console.log('timestamp %s', block.timestamp);
        console.log('period %s', period);
        console.log('total %s',  block.timestamp + period);
        registry[name] = VanityNameStruct(msg.sender, block.timestamp + period);
        emit NameRegistered(name, registry[name]);
    }

    /**
     *  @dev withdraw the fund.
     *  If balance is still locked, caller can't withdraw caller's fund
     */
    function withdraw() public {
        string memory name = names[msg.sender];
        require(block.timestamp > registry[name].expiredAt, "Your fund is still locked");
        AcceptToken.transfer(msg.sender, userBalances[msg.sender]);
        userBalances[msg.sender] = 0;
        emit Withdraw(address(this), msg.sender, userBalances[msg.sender]);
    }

    /**
     *  @dev renew the registration.
     *  If balance is still locked or fund is not enough, caller can't renew the registration
     */
    function renewRegistration() public {
        string memory name = names[msg.sender];
        require(block.timestamp > registry[name].expiredAt, "Your fund is still locked");
        uint fund = userBalances[msg.sender];
        uint256 period = getPeriod(fund);
        require(period > 0, "Invalid period");
        uint256 fee = getFee(name);
        require(AcceptToken.balanceOf(msg.sender) >= fee, "Insufficient fund");
        AcceptToken.transferFrom(msg.sender, feeCollector, fee);
        registry[name] = VanityNameStruct(msg.sender, period);
        emit RenewRegistration(msg.sender, period);
    }
}