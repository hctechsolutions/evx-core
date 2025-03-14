// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

/**
 * @title NebulaToken
 * @dev ERC-20 token for the Nebula platform with governance and vesting.
 */
contract NebulaToken is ERC20, ERC20Votes, ERC20Permit, Ownable, ERC20Pausable {
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10**18; // 100M Tokens

    struct VestingSchedule {
        uint256 totalAmount; // Total amount of tokens to be released
        uint256 released;    // Amount already released
        uint256 start;       // Vesting start date
        uint256 cliff;       // Cliff period before unlocking
        uint256 duration;    // Total vesting duration
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    /**
     * @dev Contract constructor. 
     * Mints total supply to the contract owner.
     */
    constructor() ERC20("Nebula", "NBL") ERC20Permit("Nebula") {
        _mint(msg.sender, MAX_SUPPLY);
    }

    /**
     * @dev Pauses all token transfers.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses token transfers.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Overrides transfer function to respect the pausability.
     */
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

    /**
     * @dev Overrides transferFrom function to respect the pausability.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    /**
     * @dev Sets a vesting schedule for a beneficiary.
     * @param beneficiary Address of the recipient.
     * @param totalAmount Total amount of tokens under vesting.
     * @param start Vesting start date.
     * @param cliff Cliff period before unlocking.
     * @param duration Total vesting duration.
     */
    function setVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 start,
        uint256 cliff,
        uint256 duration
    ) external onlyOwner {
        require(vestingSchedules[beneficiary].totalAmount == 0, "Vesting already set");
        require(totalAmount > 0, "Invalid amount");
        require(start + cliff + duration > block.timestamp, "Invalid vesting period");
        
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: totalAmount,
            released: 0,
            start: start,
            cliff: start + cliff,
            duration: duration
        });
    }

    /**
     * @dev Releases vested tokens according to the sender's vesting schedule.
     */
    function releaseVestedTokens() external {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(schedule.totalAmount > 0, "No vesting schedule");
        require(block.timestamp >= schedule.cliff, "Cliff period not reached");
        
        uint256 elapsed = block.timestamp - schedule.start;
        uint256 vestedAmount = (schedule.totalAmount * elapsed) / schedule.duration;
        uint256 releasable = vestedAmount - schedule.released;
        
        require(releasable > 0, "No tokens to release");
        schedule.released += releasable;
        _transfer(owner(), msg.sender, releasable);
    }

    /**
     * @dev Required for vote-based governance.
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}
