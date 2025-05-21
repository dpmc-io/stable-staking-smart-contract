// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

library BokkyPooBahsDateTimeLibrary {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint year,
        uint month,
        uint day
    ) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(
        uint _days
    ) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int _month = (80 * L) / 2447;
        int _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(
        uint year,
        uint month,
        uint day
    ) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint year,
        uint month,
        uint day,
        uint hour,
        uint minute,
        uint second
    ) internal pure returns (uint timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(
        uint timestamp
    ) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(
        uint timestamp
    )
        internal
        pure
        returns (
            uint year,
            uint month,
            uint day,
            uint hour,
            uint minute,
            uint second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(
        uint year,
        uint month,
        uint day
    ) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint year,
        uint month,
        uint day,
        uint hour,
        uint minute,
        uint second
    ) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(
        uint timestamp
    ) internal pure returns (uint daysInMonth) {
        (uint year, uint month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(
        uint year,
        uint month
    ) internal pure returns (uint daysInMonth) {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(
        uint timestamp
    ) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint timestamp) internal pure returns (uint month) {
        (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint timestamp) internal pure returns (uint day) {
        (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(
        uint timestamp,
        uint _years
    ) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(
        uint timestamp,
        uint _months
    ) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(
        uint timestamp,
        uint _days
    ) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(
        uint timestamp,
        uint _hours
    ) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(
        uint timestamp,
        uint _minutes
    ) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(
        uint timestamp,
        uint _seconds
    ) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(
        uint timestamp,
        uint _years
    ) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(
        uint timestamp,
        uint _months
    ) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(
        uint timestamp,
        uint _days
    ) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(
        uint timestamp,
        uint _hours
    ) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(
        uint timestamp,
        uint _minutes
    ) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(
        uint timestamp,
        uint _seconds
    ) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(
        uint fromTimestamp,
        uint toTimestamp
    ) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(
        uint fromTimestamp,
        uint toTimestamp
    ) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth, ) = _daysToDate(
            fromTimestamp / SECONDS_PER_DAY
        );
        (uint toYear, uint toMonth, ) = _daysToDate(
            toTimestamp / SECONDS_PER_DAY
        );
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(
        uint fromTimestamp,
        uint toTimestamp
    ) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(
        uint fromTimestamp,
        uint toTimestamp
    ) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(
        uint fromTimestamp,
        uint toTimestamp
    ) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(
        uint fromTimestamp,
        uint toTimestamp
    ) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

interface ITokenLock {
    function updateLockedAmount(
        address account,
        uint256 amount,
        bool increase
    ) external;

    function tokenLocked(address account) external view returns (uint256);
}

contract StableStaking is Ownable(msg.sender), Pausable, ReentrancyGuard {
    enum Tier {
        NoTier,
        Bronze,
        Silver,
        Gold,
        VIP
    }
    enum UserType {
        Personal,
        Institutional
    }

    struct UserInfo {
        UserType userType;
        uint256 totalStaked;
        uint256 totalLocked;
        uint256 stakeCount;
    }

    struct UserStakeInfo {
        uint256 availableStakeBalance;
        uint256 availableLockedBalance;
        uint256 totalLockedTokens;
        uint256 eligibleAdditionalInterest;
        uint256 remainingStakingAllocation;
        uint256 remainingStakingTime;
        string tierName;
        bool lockMode;
    }

    struct StakingPeriod {
        uint256 period;
        uint256 interestRate; // ppm (parts per million)
        uint256 totalActiveStaking;
        uint256 totalActiveStakeAmount;
        uint256 totalLockedAmount;
        bool exists;
    }

    struct TierInfo {
        string tier_name;
        uint256 min_locked_for_tier;
        uint256 max_locked_for_tier;
        uint256 min_stakes;
        uint256 max_stakes;
        uint256 additional_interests;
    }

    struct StakeParams {
        UserType userType;
        uint256 period;
        uint256 stakedAmount;
        bool tokenLocked;
        uint256 exp;
        bytes sig;
        uint256 stakingEndDate;
        uint256 baseInterest;
        uint256 additionalInterest;
        uint256 monthlyInterest;
        uint256 lockedTokenBalance;
        uint256 totalLocked;
        Tier userTier;
        uint256 newStakeId;
    }

    struct StakeInfo {
        uint256 stakedAmount;
        uint256 lockedAmount;
        uint256 stakingDate;
        uint256 stakingEndDate;
        uint256 principalWithdrawRequestTimestamp;
        uint256 principalWithdrawTimestamp;
        uint256 stakingPeriod;
        uint256 baseInterest;
        uint256 additionalInterest;
        uint256 monthlyInterest;
        Tier tier;
        bool tokenLocked;
        bool closed;
        bool withdrawn;
    }

    struct TokenLockedInfo {
        uint256 stakeId;
        uint256 lockedAmount;
    }

    struct PoolMetrics {
        uint256 totalPoolStaked;
        uint256 totalLocked;
        uint256 totalActiveStaked;
        uint256 totalWithdrawnStaked;
        uint256 totalDistributedInterest;
    }

    struct WithdrawalInterest {
        uint256 amount;
        uint256 timestamp;
    }

    struct WithdrawnAddress {
        uint256 lastWithdraw;
        mapping(uint256 => mapping(uint256 => WithdrawalInterest)) stakeWithdrawalHistory;
    }

    IERC20 public stakingToken;
    IERC20 public lockingToken;
    ITokenLock public tokenLock;
    using BokkyPooBahsDateTimeLibrary for uint256;

    uint256[] internal stakingPeriod;
    uint256 public bondingPeriod = 3;
    uint256 public withdrawalPeriod = 7;
    uint256 public personalMinStake = 1_000 * 10 ** 6;
    uint256 public institutionalMinStake = 50_000 * 10 ** 6;
    uint256 public totalMaxStakingPool = 5_000_000 * 10 ** 6;
    uint256 public totalStakedAmount;
    uint256 public totalLockedAmount;
    uint256 public totalActiveStaked;
    uint256 public totalRewardDistribution;
    uint256 public currentStakeId;
    uint256 public constant maxStakeAttempts = 4;
    string[] public tierCategories = [
        "Notier",
        "Bronze",
        "Silver",
        "Gold",
        "VIP"
    ];

    uint256 public MIN_VIP_THRESHOLD = 2_000_000 * 10 ** 18;
    uint256 public MIN_GOLD_THRESHOLD = 1_000_000 * 10 ** 18;
    uint256 public MIN_SILVER_THRESHOLD = 500_000 * 10 ** 18;
    uint256 public MIN_BRONZE_THRESHOLD = 100_000 * 10 ** 18;
    uint256 public MIN_NOTIER_THRESHOLD = 0;

    address public stakingPoolAndReward;
    address public lockingPool;
    address public signer;
    bool public lockMode = false;
    PoolMetrics public poolMetrics;

    event WithdrawPrincipalRequested(
        address staker,
        uint256 stakeId,
        uint256 requestedAt,
        bool isRequested
    );

    event ForceStop(
        address staker,
        uint256 stakeId,
        uint256 requestedAt,
        bool isRequested
    );
    event Withdrawn(address user, uint256 amount);
    event StakingPeriodEvent(
        uint256 periodDuration,
        uint256 periodApr,
        bool exist,
        string method
    );
    event AdditionalInterestUpdated(Tier tier, uint256 newInterestPPM);
    event MaxStakeUpdated(Tier tier, uint256 newMaxStake);
    event BondingPeriodUpdated(uint256 newBondingPeriod);
    event WithdrawalPeriodUpdated(uint256 newWithdrawalPeriod);
    event PersonalMinStakeUpdated(uint256 newMinStake);
    event InstitutionalMinStakeUpdated(uint256 newMinStake);
    event totalMaxStakingPoolUpdated(uint256 newMaxstakingPoolAndReward);
    event stakingPoolAndRewardUpdated(address newstakingPoolAndReward);
    event lockedTokenUpdated(address newlockedToken);
    event LockModeUpdated(bool oldValue, bool newValue);
    event StakingTokenUpdated(address oldAddress, address newAddress);
    event LockingTokenUpdated(address oldAddress, address newAddress);
    event ThresholdUpdated(Tier tier, uint256 newThreshold);
    event ContractStateChanged(string action, address account);

    event WithdrawnPrincipal(
        address user,
        uint256 stakeId,
        uint256 stakedAmount,
        uint256 lockedAmount,
        uint256 timeStamp
    );
    event InterestWithdrawn(
        address user,
        uint256 stakeId,
        uint256[] months,
        uint256 totalAmount,
        uint256 timeStamp
    );
    event Staked(
        address wallet,
        uint256 stakeId,
        uint256 stakedAmount,
        uint256 period,
        bool tokenLocked,
        uint256 baseInterest,
        uint256 additionalInterest,
        uint256 stakingDate,
        uint256 stakingEndDate,
        uint256 monthlyInterest,
        Tier tier
    );

    mapping(address => WithdrawnAddress) public withdrawn;
    mapping(Tier => uint256) public maxStakeForTier;
    mapping(Tier => uint256) public additionalInterestForTier;
    mapping(uint256 => StakingPeriod) public stakingPeriods;
    mapping(address => UserInfo) public users;
    mapping(bytes => bool) public usedSig;
    mapping(address => mapping(uint256 => StakeInfo)) public stakes;
    mapping(address => TokenLockedInfo) public tokenLocked;

    constructor(
        address _stakingToken,
        address _stakingPoolAndReward,
        address _lockingToken,
        address _lockingPool,
        address _signer,
        bool _lockMode
    ) {
        require(_stakingToken != address(0), "Invalid staking token");
        require(_stakingPoolAndReward != address(0), "Invalid staking pool");
        require(_signer != address(0), "Invalid signer");

        stakingToken = IERC20(_stakingToken);
        stakingPoolAndReward = _stakingPoolAndReward;
        lockingToken = IERC20(_lockingToken);
        tokenLock = ITokenLock(_lockingToken);
        lockingPool = _lockingPool;
        signer = _signer;
        lockMode = _lockMode;

        additionalInterestForTier[Tier.NoTier] = 0;
        additionalInterestForTier[Tier.Bronze] = 10_000; // 1.00% in PPM
        additionalInterestForTier[Tier.Silver] = 15_000; // 1.50% in PPM
        additionalInterestForTier[Tier.Gold] = 20_000; // 2.00% in PPM
        additionalInterestForTier[Tier.VIP] = 20_000; // 2.00% in PPM

        maxStakeForTier[Tier.NoTier] = 5_000 * 10 ** 6; // 5k USDT
        maxStakeForTier[Tier.Bronze] = 10_000 * 10 ** 6; // 10k USDT
        maxStakeForTier[Tier.Silver] = 25_000 * 10 ** 6; // 25k USDT
        maxStakeForTier[Tier.Gold] = 50_000 * 10 ** 6; // 50k USDT
        maxStakeForTier[Tier.VIP] = 1_000_000 * 10 ** 6; // 1M USDT

        // Initialize staking periods with APRs in PPM (e.g., 7.00% is 70000 PPM)
        addStakingPeriod(6, 70_000); // 7.00% APR
        addStakingPeriod(9, 70_000); // 7.00% APR
        addStakingPeriod(12, 70_000); // 7.00% APR
        addStakingPeriod(18, 70_000); // 7.00% APR
    }

    function pause() public onlyOwner {
        _pause();
        emit ContractStateChanged("Paused", msg.sender);
    }

    function unpause() public onlyOwner {
        _unpause();
        emit ContractStateChanged("Unpaused", msg.sender);
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Invalid address.");
        _;
    }

    function updateLockMode(bool _status) public onlyOwner {
        require(
            _status != lockMode,
            "New status must differ from the current one."
        );
        emit LockModeUpdated(lockMode, _status);

        lockMode = _status;
    }

    function getLockedAmount(address account) internal view returns (uint256) {
        return
            address(tokenLock) == address(0)
                ? 0
                : tokenLock.tokenLocked(account);
    }

    function updateUserLockedAmount(
        address account,
        uint256 amount,
        bool increase
    ) internal {
        if (address(tokenLock) != address(0)) {
            tokenLock.updateLockedAmount(account, amount, increase);
        }
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(
        bytes32 _hashedMessage,
        bytes memory sig
    ) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(_hashedMessage, v, r, s);
    }

    function updateVipThreshold(uint256 _vip) public onlyOwner {
        MIN_VIP_THRESHOLD = _vip;
        emit ThresholdUpdated(Tier.VIP, _vip);
    }

    function updateGoldThreshold(uint256 _gold) public onlyOwner {
        MIN_GOLD_THRESHOLD = _gold;
        emit ThresholdUpdated(Tier.Gold, _gold);
    }

    function updateSilverThreshold(uint256 _silver) public onlyOwner {
        MIN_SILVER_THRESHOLD = _silver;
        emit ThresholdUpdated(Tier.Silver, _silver);
    }

    function updateBronzeThreshold(uint256 _bronze) public onlyOwner {
        MIN_BRONZE_THRESHOLD = _bronze;
        emit ThresholdUpdated(Tier.Bronze, _bronze);
    }

    function updateNotierThreshold(uint256 _notier) public onlyOwner {
        MIN_NOTIER_THRESHOLD = _notier;
        emit ThresholdUpdated(Tier.NoTier, _notier);
    }

    function updateStakingPoolAndReward(
        address _newAddress
    ) external onlyValidAddress(_newAddress) onlyOwner {
        stakingPoolAndReward = _newAddress;
        emit stakingPoolAndRewardUpdated(_newAddress);
    }

    function updateLockingPool(
        address _newAddress
    ) external onlyValidAddress(_newAddress) onlyOwner {
        lockingPool = _newAddress;
        emit lockedTokenUpdated(_newAddress);
    }

    function updateBondingPeriod(uint256 _newBondingPeriod) external onlyOwner {
        require(_newBondingPeriod > 0, "Bonding period must be greater than 0");
        bondingPeriod = _newBondingPeriod;

        emit BondingPeriodUpdated(_newBondingPeriod);
    }

    function updateWithdrawalPeriod(
        uint256 _newWithdrawalPeriod
    ) external onlyOwner {
        require(
            _newWithdrawalPeriod > 0,
            "Withdrawal period must be greater than 0"
        );
        withdrawalPeriod = _newWithdrawalPeriod;

        emit WithdrawalPeriodUpdated(_newWithdrawalPeriod);
    }

    function updatePersonalMinStake(uint256 _newMinStake) external onlyOwner {
        require(
            _newMinStake > 0,
            "Personal minimum stake must be greater than 0"
        );
        personalMinStake = _newMinStake;

        emit PersonalMinStakeUpdated(_newMinStake);
    }

    function updateInstitutionalMinStake(
        uint256 _newMinStake
    ) external onlyOwner {
        require(
            _newMinStake > 0,
            "Institutional minimum stake must be greater than 0"
        );
        institutionalMinStake = _newMinStake;

        emit InstitutionalMinStakeUpdated(_newMinStake);
    }

    function updateTotalMaxStakingPool(uint256 _newMax) external onlyOwner {
        require(
            _newMax > 0,
            "Total maximum staking pool must be greater than 0"
        );
        totalMaxStakingPool = _newMax;

        emit totalMaxStakingPoolUpdated(_newMax);
    }

    function updateMaxStakeForTier(
        Tier _tier,
        uint256 _newMaxStake
    ) external onlyOwner {
        require(_newMaxStake > 0, "Max stake must be greater than 0");
        maxStakeForTier[_tier] = _newMaxStake;
        emit MaxStakeUpdated(_tier, _newMaxStake);
    }

    function updateAdditionalInterestForTier(
        Tier _tier,
        uint256 _newInterestPPM
    ) external onlyOwner {
        require(
            _newInterestPPM >= 10_000 && _newInterestPPM <= 1_000_000,
            "Interest must be between 1% and 100%."
        );
        additionalInterestForTier[_tier] = _newInterestPPM;
        emit AdditionalInterestUpdated(_tier, _newInterestPPM);
    }

    function updateStakingToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Invalid staking token address");
        address oldAddress = address(stakingToken);

        stakingToken = IERC20(_newAddress);

        emit StakingTokenUpdated(oldAddress, _newAddress);
    }

    function updateLockingToken(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Invalid locking token address");
        address oldAddress = address(lockingToken);

        lockingToken = IERC20(_newAddress);
        tokenLock = ITokenLock(_newAddress);

        emit LockingTokenUpdated(oldAddress, _newAddress);
    }

    function getUserTier(
        uint256 _lockedAmount
    ) public view returns (Tier tier) {
        if (_lockedAmount >= MIN_VIP_THRESHOLD) {
            return Tier.VIP;
        } else if (_lockedAmount >= MIN_GOLD_THRESHOLD) {
            return Tier.Gold;
        } else if (_lockedAmount >= MIN_SILVER_THRESHOLD) {
            return Tier.Silver;
        } else if (_lockedAmount >= MIN_BRONZE_THRESHOLD) {
            return Tier.Bronze;
        } else if (_lockedAmount < MIN_BRONZE_THRESHOLD) {
            return Tier.NoTier;
        }
    }

    function getGlobalUserTier(
        address account,
        UserType userType
    ) public view returns (Tier tier) {
        uint256 availableBalance = lockMode
            ? lockingToken.balanceOf(account)
            : 0;
        uint256 totalLocked = lockMode
            ? getLockedAmount(account) + availableBalance
            : 0;

        uint256 _lockedAmount = userType == UserType.Personal &&
            totalLocked >= MIN_VIP_THRESHOLD
            ? MIN_GOLD_THRESHOLD + 1
            : totalLocked;

        if (_lockedAmount >= MIN_VIP_THRESHOLD) {
            return Tier.VIP;
        } else if (_lockedAmount >= MIN_GOLD_THRESHOLD) {
            return Tier.Gold;
        } else if (_lockedAmount >= MIN_SILVER_THRESHOLD) {
            return Tier.Silver;
        } else if (_lockedAmount >= MIN_BRONZE_THRESHOLD) {
            return Tier.Bronze;
        } else if (_lockedAmount < MIN_BRONZE_THRESHOLD) {
            return Tier.NoTier;
        }
    }

    function getTierName(Tier tier) internal pure returns (string memory) {
        if (tier == Tier.NoTier) return "NoTier";
        if (tier == Tier.Bronze) return "Bronze";
        if (tier == Tier.Silver) return "Silver";
        if (tier == Tier.Gold) return "Gold";
        if (tier == Tier.VIP) return "VIP";
        return "";
    }

    function getAllTiers() public view returns (TierInfo[5] memory) {
        TierInfo[5] memory tiersInfo;

        tiersInfo[0] = TierInfo({
            tier_name: "NoTier",
            min_locked_for_tier: 0,
            max_locked_for_tier: MIN_BRONZE_THRESHOLD - 1,
            min_stakes: personalMinStake,
            max_stakes: maxStakeForTier[Tier.NoTier],
            additional_interests: additionalInterestForTier[Tier.NoTier]
        });

        tiersInfo[1] = TierInfo({
            tier_name: "Bronze",
            min_locked_for_tier: MIN_BRONZE_THRESHOLD,
            max_locked_for_tier: MIN_SILVER_THRESHOLD - 1,
            min_stakes: personalMinStake,
            max_stakes: maxStakeForTier[Tier.Bronze],
            additional_interests: additionalInterestForTier[Tier.Bronze]
        });

        tiersInfo[2] = TierInfo({
            tier_name: "Silver",
            min_locked_for_tier: MIN_SILVER_THRESHOLD,
            max_locked_for_tier: MIN_GOLD_THRESHOLD - 1,
            min_stakes: personalMinStake,
            max_stakes: maxStakeForTier[Tier.Silver],
            additional_interests: additionalInterestForTier[Tier.Silver]
        });

        tiersInfo[3] = TierInfo({
            tier_name: "Gold",
            min_locked_for_tier: MIN_GOLD_THRESHOLD,
            max_locked_for_tier: MIN_VIP_THRESHOLD - 1,
            min_stakes: personalMinStake,
            max_stakes: maxStakeForTier[Tier.Gold],
            additional_interests: additionalInterestForTier[Tier.Gold]
        });

        tiersInfo[4] = TierInfo({
            tier_name: "VIP",
            min_locked_for_tier: MIN_VIP_THRESHOLD,
            max_locked_for_tier: 0,
            min_stakes: institutionalMinStake,
            max_stakes: maxStakeForTier[Tier.VIP],
            additional_interests: additionalInterestForTier[Tier.VIP]
        });

        return tiersInfo;
    }

    function calculateStakingInterest(
        uint256 totalDays,
        uint256 totalDaysInMonth,
        uint256 totalStakingAmount,
        uint256 interestRate
    ) public pure returns (uint256) {
        require(totalDays <= totalDaysInMonth, "Invalid max totalDays");
        uint256 monthlyInterest = calculateMonthlyStakingInterest(
            totalStakingAmount,
            interestRate
        );
        uint256 proRate = (totalDays * monthlyInterest) / totalDaysInMonth;
        uint256 monthlyInterestCalculated = totalDays == totalDaysInMonth
            ? monthlyInterest
            : proRate;
        return monthlyInterestCalculated;
    }

    function calculateMonthlyStakingInterest(
        uint256 stakedAmount,
        uint256 interestRate
    ) internal pure returns (uint256) {
        // Calculate annual interest
        uint256 annualInterest = (stakedAmount * interestRate) / 1000000;

        // For monthly interest, assuming 12 months
        uint256 monthlyInterest = annualInterest / 12;

        return monthlyInterest;
    }

    function addStakingPeriod(
        uint256 _period,
        uint256 _interestRate
    ) public onlyOwner {
        require(
            stakingPeriods[_period].period != _period,
            "Period is already exist."
        );
        require(_interestRate >= 10_000, "Interest rate must be at least 1%.");
        stakingPeriods[_period] = StakingPeriod(
            _period,
            _interestRate,
            0,
            0,
            0,
            true
        );
        stakingPeriod.push(_period);
        emit StakingPeriodEvent(_period, _interestRate, true, "add");
    }

    function updateStakingPeriod(
        uint256 _period,
        uint256 _interestRate
    ) public onlyOwner {
        require(
            stakingPeriods[_period].period == _period,
            "Period is not exist."
        );
        require(_interestRate >= 10_000, "Interest rate must be at least 1%.");
        stakingPeriods[_period].interestRate = _interestRate;
        emit StakingPeriodEvent(_period, _interestRate, true, "update");
    }

    function disableStakingPeriod(uint256 _period) public {
        require(
            stakingPeriods[_period].period == _period,
            "Period is not exist."
        );
        stakingPeriods[_period].exists = false;
        emit StakingPeriodEvent(_period, 0, false, "disable");
    }

    function enableStakingPeriod(
        uint256 _period,
        uint256 _interestRate
    ) public {
        require(
            stakingPeriods[_period].period == _period,
            "Period is not exist."
        );
        stakingPeriods[_period].exists = true;
        stakingPeriods[_period].interestRate = _interestRate;
        emit StakingPeriodEvent(_period, _interestRate, false, "enable");
    }

    function periodList()
        public
        view
        returns (
            uint256[] memory _period,
            uint256[] memory _interestRate,
            uint256[] memory _totalActiveStaking,
            uint256[] memory _totalActiveStakeAmount,
            uint256[] memory _totalLockedAmount,
            bool[] memory _isActive
        )
    {
        uint256[] memory _periodVal = new uint256[](37);
        uint256[] memory _interestRateVal = new uint256[](37);
        uint256[] memory _totalActiveStakingVal = new uint256[](37);
        uint256[] memory _totalActiveStakeAmountVal = new uint256[](37);
        uint256[] memory _totalLockedAmountVal = new uint256[](37);
        bool[] memory _isActiveVal = new bool[](37);
        uint256 count = 0;

        for (uint256 i = 0; i < stakingPeriod.length; i++) {
            uint256 periodKey = stakingPeriod[i];
            StakingPeriod storage sp = stakingPeriods[periodKey];
            if (sp.period > 0) {
                _periodVal[count] = periodKey;
                _interestRateVal[count] = sp.interestRate;
                _totalActiveStakingVal[count] = sp.totalActiveStaking;
                _totalActiveStakeAmountVal[count] = sp.totalActiveStakeAmount;
                _totalLockedAmountVal[count] = sp.totalLockedAmount;
                _isActiveVal[count] = sp.exists;
                count++;
            }
        }

        assembly {
            mstore(_periodVal, count)
        }

        assembly {
            mstore(_interestRateVal, count)
        }

        assembly {
            mstore(_totalActiveStakingVal, count)
        }

        assembly {
            mstore(_totalActiveStakeAmountVal, count)
        }

        assembly {
            mstore(_totalLockedAmountVal, count)
        }

        assembly {
            mstore(_isActiveVal, count)
        }

        return (
            _periodVal,
            _interestRateVal,
            _totalActiveStakingVal,
            _totalActiveStakeAmountVal,
            _totalLockedAmountVal,
            _isActiveVal
        );
    }

    function stakeWithLockingDisabled(
        UserType _userType,
        uint256 _period,
        uint256 _stakedAmount,
        bool _isTokenLocked,
        uint256 exp,
        bytes memory sig
    ) internal {
        validateStakeConditions(
            _userType,
            _period,
            _stakedAmount,
            _isTokenLocked
        );

        StakeParams memory params;
        params.userType = _userType;
        params.period = _period;
        params.stakedAmount = _stakedAmount;
        params.lockedTokenBalance = 0;
        params.tokenLocked = false; // Explicitly setting to false, as locking is disabled
        params.exp = exp;
        params.sig = sig;
        params.stakingEndDate = block.timestamp.addMonths(_period);
        params.baseInterest = stakingPeriods[params.period].interestRate;
        params.additionalInterest = 0;
        params.monthlyInterest = calculateMonthlyStakingInterest(
            _stakedAmount,
            stakingPeriods[_period].interestRate
        );
        params.userTier = Tier.NoTier; // No tier since locking is disabled

        // Transfer USDT to staking pool address
        handleTransfers(msg.sender, params.stakedAmount, 0);

        // Set up the stake info
        params.newStakeId = createStakeInfo(msg.sender, params);

        // Emit event
        emit Staked(
            msg.sender,
            params.newStakeId,
            params.stakedAmount,
            params.period,
            params.tokenLocked,
            params.baseInterest,
            params.additionalInterest,
            block.timestamp,
            params.stakingEndDate,
            params.monthlyInterest,
            params.userTier
        );
    }

    function stakeWithOptionalLock(
        UserType _userType,
        uint256 _period,
        uint256 _stakedAmount,
        bool _isTokenLocked,
        uint256 exp,
        bytes memory sig
    ) internal {
        validateStakeConditions(
            _userType,
            _period,
            _stakedAmount,
            _isTokenLocked
        );
        uint256 totalAmountLocked = getLockedAmount(msg.sender);
        StakeParams memory params;
        params.userType = _userType;
        params.period = _period;
        params.stakedAmount = _stakedAmount;
        params.tokenLocked = _isTokenLocked;
        params.exp = exp;
        params.sig = sig;
        params.stakingEndDate = block.timestamp.addMonths(_period);
        params.lockedTokenBalance = _isTokenLocked
            ? lockingToken.balanceOf(msg.sender)
            : 0;
        params.totalLocked = totalAmountLocked + params.lockedTokenBalance;
        params.userTier = getUserTier(
            params.totalLocked + lockingToken.balanceOf(msg.sender)
        );
        params.baseInterest = stakingPeriods[params.period].interestRate;
        params.additionalInterest = additionalInterestForTier[params.userTier];
        params.monthlyInterest = calculateMonthlyStakingInterest(
            _stakedAmount,
            stakingPeriods[_period].interestRate + params.additionalInterest
        );
        updateUserLockedAmount(msg.sender, params.lockedTokenBalance, true);
        handleTransfers(
            msg.sender,
            params.stakedAmount,
            params.lockedTokenBalance
        );

        totalLockedAmount += params.lockedTokenBalance;
        users[msg.sender].totalLocked += params.lockedTokenBalance;
        poolMetrics.totalLocked += params.lockedTokenBalance;

        // Set up the stake info
        params.newStakeId = createStakeInfo(msg.sender, params);

        // Update tokenLocked info
        updateTokenLockedInfo(msg.sender, params);

        // Emit event
        emit Staked(
            msg.sender,
            params.newStakeId,
            params.stakedAmount,
            params.period,
            params.tokenLocked,
            params.baseInterest,
            params.additionalInterest,
            block.timestamp,
            params.stakingEndDate,
            params.monthlyInterest,
            params.userTier
        );
    }

    function createStakeInfo(
        address user,
        StakeParams memory params
    ) internal returns (uint256) {
        uint256 newStakeId = ++currentStakeId;
        stakes[user][newStakeId] = StakeInfo({
            stakedAmount: params.stakedAmount,
            lockedAmount: params.lockedTokenBalance,
            stakingDate: block.timestamp,
            stakingEndDate: params.stakingEndDate,
            principalWithdrawRequestTimestamp: 0,
            principalWithdrawTimestamp: 0,
            stakingPeriod: params.period,
            baseInterest: params.baseInterest,
            additionalInterest: params.additionalInterest,
            monthlyInterest: params.monthlyInterest,
            tier: params.userTier,
            tokenLocked: params.tokenLocked,
            closed: false,
            withdrawn: false
        });
        totalStakedAmount += params.stakedAmount;
        totalActiveStaked++;

        users[user].userType = params.userType;
        users[user].totalStaked += params.stakedAmount;
        users[user].stakeCount++;

        stakingPeriods[params.period].totalActiveStaking++;
        stakingPeriods[params.period].totalActiveStakeAmount += params
            .stakedAmount;
        stakingPeriods[params.period].totalLockedAmount += params
            .lockedTokenBalance;

        poolMetrics.totalPoolStaked += params.stakedAmount;
        poolMetrics.totalActiveStaked++;

        return newStakeId;
    }

    function updateTokenLockedInfo(
        address user,
        StakeParams memory params
    ) internal {
        tokenLocked[user] = TokenLockedInfo({
            stakeId: (stakes[user][tokenLocked[user].stakeId].stakingEndDate <
                params.stakingEndDate)
                ? params.newStakeId
                : tokenLocked[user].stakeId,
            lockedAmount: params.totalLocked
        });
    }

    function stake(
        UserType _userType,
        uint256 _period,
        uint256 _stakedAmount,
        bool _isTokenLocked,
        uint256 exp,
        bytes memory sig
    ) external whenNotPaused nonReentrant {
        // Verify the signature
        require(exp >= block.timestamp, "Signature expired.");
        bytes32 _hashedMessage = keccak256(
            abi.encodePacked(
                address(this),
                msg.sender,
                _userType,
                _period,
                _stakedAmount,
                _isTokenLocked,
                exp
            )
        );
        require(!usedSig[sig], "Signature already used.");
        require(
            recoverSigner(_hashedMessage, sig) == signer,
            "Invalid signer."
        );

        usedSig[sig] = true;

        if (!lockMode) {
            stakeWithLockingDisabled(
                _userType,
                _period,
                _stakedAmount,
                _isTokenLocked,
                exp,
                sig
            );
        } else {
            stakeWithOptionalLock(
                _userType,
                _period,
                _stakedAmount,
                _isTokenLocked,
                exp,
                sig
            );
        }
    }

    function getTierMinimumLocked(Tier tier) public view returns (uint256) {
        if (tier == Tier.VIP) return MIN_VIP_THRESHOLD;
        if (tier == Tier.Gold) return MIN_GOLD_THRESHOLD;
        if (tier == Tier.Silver) return MIN_SILVER_THRESHOLD;
        if (tier == Tier.Bronze) return MIN_BRONZE_THRESHOLD;
        return MIN_NOTIER_THRESHOLD;
    }

    function validateStakeConditions(
        UserType _userType,
        uint256 _period,
        uint256 _stakedAmount,
        bool _isTokenLocked
    ) internal view {
        require(
            stakingPeriods[_period].exists,
            "Staking period is not available."
        );
        require(
            totalStakedAmount + _stakedAmount <= totalMaxStakingPool,
            "Staking pool amount exceeds the maximum limit."
        );
        require(
            users[msg.sender].stakeCount + 1 <= maxStakeAttempts,
            "Stake count exceeds max limit."
        );

        uint256 totalLocked = getLockedAmount(msg.sender) +
            lockingToken.balanceOf(msg.sender);
        uint256 userLockedAmount = _userType == UserType.Personal &&
            totalLocked >= MIN_VIP_THRESHOLD
            ? MIN_GOLD_THRESHOLD + 1
            : totalLocked;
        Tier userTier = getUserTier(userLockedAmount);
        uint256 maxTierStake = !lockMode
            ? maxStakeForTier[Tier.VIP]
            : maxStakeForTier[userTier];
        if (_userType == UserType.Personal) {
            require(
                _stakedAmount >= personalMinStake,
                "Stake amount below minimum for personal users."
            );
            require(
                users[msg.sender].totalStaked + _stakedAmount <= maxTierStake,
                "Stake amount exceeds max limit."
            );
        } else if (_userType == UserType.Institutional) {
            require(
                _stakedAmount >= institutionalMinStake,
                "Stake amount below minimum for institutional users."
            );
            require(
                users[msg.sender].totalStaked + _stakedAmount <= maxTierStake,
                "Stake amount exceeds max limit."
            );
            require(
                _period >= 12,
                "Institutional users must stake for at least 12 months."
            );
        }
        // DPT lock is enabled
        if (lockMode) {
            if (_isTokenLocked) {
                require(
                    lockingToken.balanceOf(msg.sender) >=
                        getTierMinimumLocked(userTier),
                    "Minimum lock amount not met"
                );
            }
        } else {
            require(!_isTokenLocked, "Locking token is not supported yet.");
        }
    }

    function handleTransfers(
        address staker,
        uint256 _stakedAmount,
        uint256 _lockedAmount
    ) internal {
        stakingToken.transferFrom(staker, stakingPoolAndReward, _stakedAmount);
        if (_lockedAmount > 0) {
            lockingToken.transferFrom(staker, lockingPool, _lockedAmount);
        }
    }

    function forceStop(
        uint256 _stakeId,
        address _staker
    ) external onlyOwner nonReentrant {
        // Validate stake exists
        StakeInfo storage staking = stakes[_staker][_stakeId];
        require(staking.stakedAmount > 0, "Staking record not found.");
        require(!staking.closed, "Stake has already been closed.");

        // Update stake information
        staking.principalWithdrawRequestTimestamp = block.timestamp;
        staking.closed = true;

        // Update pool metrics
        poolMetrics.totalPoolStaked -= staking.stakedAmount;
        poolMetrics.totalActiveStaked = poolMetrics.totalActiveStaked > 0
            ? poolMetrics.totalActiveStaked - 1
            : 0; // Avoid underflow

        // Update user metrics
        UserInfo storage user = users[_staker];
        user.totalStaked -= staking.stakedAmount;
        user.stakeCount = user.stakeCount > 0 ? user.stakeCount - 1 : 0; // Avoid underflow

        if (tokenLocked[_staker].stakeId == _stakeId) {
            uint256 locked = tokenLocked[_staker].lockedAmount;

            poolMetrics.totalLocked -= locked;
            stakingPeriods[staking.stakingPeriod].totalLockedAmount -= locked;
        }

        totalStakedAmount -= staking.stakedAmount;
        totalActiveStaked--;

        stakingPeriods[staking.stakingPeriod].totalActiveStaking--;
        stakingPeriods[staking.stakingPeriod].totalActiveStakeAmount -= staking
            .stakedAmount;

        // Emit event
        emit ForceStop(_staker, _stakeId, block.timestamp, true);
    }

    function requestWithdrawPrincipal(
        uint256 _stakeId,
        uint256 exp,
        bytes memory sig
    ) external nonReentrant {
        require(exp >= block.timestamp, "Signature expired");
        bytes32 _hashedMessage = keccak256(
            abi.encodePacked(address(this), msg.sender, _stakeId, exp)
        );

        require(!usedSig[sig], "Signature already used.");
        require(
            recoverSigner(_hashedMessage, sig) == signer,
            "Invalid signer."
        );

        usedSig[sig] = true;

        // Validate stake exists
        StakeInfo storage staking = stakes[msg.sender][_stakeId];
        require(staking.stakedAmount > 0, "Staking record not found.");
        require(!staking.closed, "Stake has already been closed.");
        // require(
        //     staking.stakingEndDate <= block.timestamp,
        //     "Staking period has not ended yet."
        // );

        // Update stake information
        staking.principalWithdrawRequestTimestamp = block.timestamp;
        staking.closed = true;

        // Update pool metrics
        poolMetrics.totalPoolStaked -= staking.stakedAmount;
        poolMetrics.totalActiveStaked = poolMetrics.totalActiveStaked > 0
            ? poolMetrics.totalActiveStaked - 1
            : 0; // Avoid underflow

        // Update user metrics
        UserInfo storage user = users[msg.sender];
        user.totalStaked -= staking.stakedAmount;
        user.stakeCount = user.stakeCount > 0 ? user.stakeCount - 1 : 0; // Avoid underflow

        if (tokenLocked[msg.sender].stakeId == _stakeId) {
            uint256 lockedAmt = tokenLocked[msg.sender].lockedAmount;

            poolMetrics.totalLocked -= lockedAmt;
            stakingPeriods[staking.stakingPeriod].totalLockedAmount -= staking
                .lockedAmount;
        }

        totalStakedAmount -= staking.stakedAmount;
        totalActiveStaked--;

        stakingPeriods[staking.stakingPeriod].totalActiveStaking--;
        stakingPeriods[staking.stakingPeriod].totalActiveStakeAmount -= staking
            .stakedAmount;

        // Emit event
        emit WithdrawPrincipalRequested(
            msg.sender,
            _stakeId,
            block.timestamp,
            true
        );
    }

    function withdrawPrincipal(
        uint256 _stakeId,
        uint256 exp,
        bytes memory sig
    ) external nonReentrant {
        require(exp >= block.timestamp, "Signature expired");
        bytes32 _hashedMessage = keccak256(
            abi.encodePacked(address(this), msg.sender, _stakeId, exp)
        );

        require(!usedSig[sig], "Signature already used.");
        require(
            recoverSigner(_hashedMessage, sig) == signer,
            "Invalid signer."
        );

        usedSig[sig] = true;

        // Validate stake exists
        StakeInfo storage staking = stakes[msg.sender][_stakeId];
        require(staking.stakedAmount > 0, "Staking record not found.");
        require(staking.closed, "Staking must be closed before proceeding.");
        require(
            !staking.withdrawn,
            "Withdrawal rejected: stake has already been claimed."
        );

        // Update stake information
        staking.principalWithdrawTimestamp = block.timestamp;
        staking.withdrawn = true;

        stakingToken.transferFrom(
            stakingPoolAndReward,
            msg.sender,
            staking.stakedAmount
        );
        if (staking.lockedAmount > 0) {
            if (tokenLocked[msg.sender].stakeId == _stakeId) {
                UserInfo storage user = users[msg.sender];
                uint256 lockedAmt = tokenLocked[msg.sender].lockedAmount;

                lockingToken.transferFrom(lockingPool, msg.sender, lockedAmt);
                tokenLocked[msg.sender].lockedAmount = 0;
                user.totalLocked = 0;

                updateUserLockedAmount(msg.sender, lockedAmt, false);
            }
        }

        // Emit event
        emit WithdrawnPrincipal(
            msg.sender,
            _stakeId,
            staking.stakedAmount,
            staking.lockedAmount,
            block.timestamp
        );
    }

    function withdrawInterest(
        uint256 _stakeId,
        uint256[] memory _months,
        uint256[] memory _interests,
        uint256 exp,
        bytes memory sig
    ) external {
        require(
            _months.length == _interests.length,
            "The lengths of the months and interest arrays must be equal."
        );
        require(
            _months.length > 0,
            "At least one month must be specified for withdrawal."
        );

        // Verify the signature
        bytes32 _hashedMessage = keccak256(
            abi.encodePacked(
                address(this),
                msg.sender,
                _stakeId,
                _months,
                _interests,
                exp
            )
        );

        require(!usedSig[sig], "Signature already used");
        require(recoverSigner(_hashedMessage, sig) == signer, "Invalid signer");

        usedSig[sig] = true;

        StakeInfo storage staking = stakes[msg.sender][_stakeId];
        WithdrawnAddress storage user = withdrawn[msg.sender];
        uint256 totalInterest = 0;

        for (uint256 i = 0; i < _months.length; i++) {
            uint256 month = _months[i];
            uint256 interest = _interests[i];

            require(
                interest > 0,
                "Interest must be a positive value greater than zero."
            );
            require(
                interest <= staking.monthlyInterest,
                "Interest must not exceed the allowed monthly interest."
            );

            WithdrawalInterest storage existingWithdrawal = user
                .stakeWithdrawalHistory[_stakeId][month];
            require(
                existingWithdrawal.amount == 0,
                "Interest has already been withdrawn for the specified stake ID and month."
            );

            totalInterest += interest;
            user.stakeWithdrawalHistory[_stakeId][month] = WithdrawalInterest({
                amount: interest,
                timestamp: block.timestamp
            });
        }

        stakingToken.transferFrom(
            stakingPoolAndReward,
            msg.sender,
            totalInterest
        );

        totalRewardDistribution += totalInterest;
        user.lastWithdraw = block.timestamp;

        emit InterestWithdrawn(
            msg.sender,
            _stakeId,
            _months,
            totalInterest,
            block.timestamp
        );
    }

    function getUserStakeInfo(
        address _user,
        UserType userType
    ) public view returns (UserStakeInfo memory) {
        uint256 lockedTokenBalance = lockMode
            ? lockingToken.balanceOf(_user)
            : 0;
        uint256 totalLocked = lockMode
            ? getLockedAmount(_user) + lockedTokenBalance
            : 0;
        uint256 userLockedAmount = userType == UserType.Personal &&
            totalLocked >= MIN_VIP_THRESHOLD
            ? MIN_GOLD_THRESHOLD + 1
            : totalLocked;
        Tier userTier = lockMode
            ? getUserTier(userLockedAmount)
            : getUserTier(0);
        uint256 maxTierStake = !lockMode
            ? maxStakeForTier[Tier.VIP]
            : maxStakeForTier[userTier];

        uint256 personalRemainingStakingAlloc = (
            users[_user].totalStaked >= maxTierStake
                ? 0
                : maxTierStake - users[_user].totalStaked
        );

        uint256 orgRemainingStakingAlloc = (
            users[_user].totalStaked >= maxStakeForTier[Tier.VIP]
                ? 0
                : maxStakeForTier[Tier.VIP] - users[_user].totalStaked
        );
        return
            UserStakeInfo({
                availableStakeBalance: stakingToken.balanceOf(_user),
                availableLockedBalance: lockedTokenBalance,
                totalLockedTokens: lockMode ? getLockedAmount(_user) : 0,
                eligibleAdditionalInterest: additionalInterestForTier[userTier],
                remainingStakingAllocation: userType == UserType.Personal
                    ? personalRemainingStakingAlloc
                    : orgRemainingStakingAlloc,
                remainingStakingTime: maxStakeAttempts -
                    users[_user].stakeCount,
                tierName: getTierName(userTier),
                lockMode: lockMode
            });
    }
}
