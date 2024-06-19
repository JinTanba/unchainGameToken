// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BiscuitToken is ERC20 {
    constructor() ERC20("Biscuit", "BCT") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}