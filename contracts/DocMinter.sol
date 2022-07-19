// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";

contract DocMinter {

    event Received(uint256 value);
    event Minting(uint256 value);
    event Minted(uint256 value);
    event Refunded(uint256 value);

    address payable private mocAddr;
    address private docAddr;
    address private mocExchangeAddr;
    address private mocInrateAddr;
    address private mocVendorAddr;

    constructor(address payable _mocAddr, address _docAddr, address _mocExchangeAddr, address _mocInrateAddr, address _mocVendorAddr) {
        mocAddr = _mocAddr;
        docAddr = _docAddr;
        mocExchangeAddr = _mocExchangeAddr;
        mocInrateAddr = _mocInrateAddr;
        mocVendorAddr = _mocVendorAddr;
    }

    receive() external payable {
        emit Received(msg.value);
    }

    function mintDoc(address payable receiverAddr, address payable refundAddr) payable external returns (uint256) {
        emit Minting(msg.value);

        bool success;
        bytes memory _returnData;

        uint256 oldBalance = address(this).balance - msg.value;

        (success, _returnData) = docAddr.call(abi.encodeWithSignature("balanceOf(address)", address(this)));
        if (!success) {
            string memory _revertMsg = _getRevertMsg(_returnData);
            revert(_revertMsg);
        }
        (uint256 oldDocBalance) = abi.decode(_returnData, (uint256));

        uint256 fee = _calcCommission();

        (success, _returnData) = mocAddr.call{value: msg.value}(abi.encodeWithSignature("mintDocVendors(uint256,address)", msg.value - fee, mocVendorAddr));
        if (!success) {
            string memory _revertMsg = _getRevertMsg(_returnData);
            revert(_revertMsg);
        }

        (success, _returnData) = docAddr.call(abi.encodeWithSignature("balanceOf(address)", address(this)));
        if (!success) {
            string memory _revertMsg = _getRevertMsg(_returnData);
            revert(_revertMsg);
        }
        (uint256 docBalance) = abi.decode(_returnData, (uint256));

        uint256 mintedDoc = docBalance - oldDocBalance;
        emit Minted(mintedDoc);

        (success, _returnData) = docAddr.call(abi.encodeWithSignature("transfer(address,uint256)", receiverAddr, mintedDoc));
        if (!success) {
            string memory _revertMsg = _getRevertMsg(_returnData);
            revert(_revertMsg);
        }

        uint256 reminder = address(this).balance - oldBalance;
        if (reminder > 0) {
            (success, ) = refundAddr.call{value: reminder}("");
            require(success, "Failed to send reminder to refundAddr");

            emit Refunded(reminder);
        }

        return mintedDoc;
    }

    function _calcCommission() internal returns (uint256) {
        bool success;
        bytes memory _returnData;

        (success, _returnData) = mocInrateAddr.call(abi.encodeWithSignature("MINT_DOC_FEES_MOC()"));
        require(success, "MINT_DOC_FEES_MOC() failed");
        (uint8 txTypeFeesMOC) = abi.decode(_returnData, (uint8));

        (success, _returnData) = mocInrateAddr.call(abi.encodeWithSignature("MINT_DOC_FEES_RBTC()"));
        require(success, "MINT_DOC_FEES_RBTC() failed");
        (uint8 txTypeFeesRBTC) = abi.decode(_returnData, (uint8));

        (success, _returnData) = mocExchangeAddr.call(abi.encodeWithSignature("calculateCommissionsWithPrices((address,uint256,uint8,uint8,address))",
            address(this), msg.value, txTypeFeesMOC, txTypeFeesRBTC, mocVendorAddr));
        if (!success) {
            string memory _revertMsg = _getRevertMsg(_returnData);
            revert(_revertMsg);
        }

        // (uint256 btcCommission, uint256 mocCommission, uint256 btcPrice, uint256 mocPrice, uint256 btcMarkup, uint256 mocMarkup)
        (uint256 btcCommission, , , , uint256 btcMarkup, uint256 mocMarkup) = abi.decode(_returnData, (uint256, uint256, uint256, uint256, uint256, uint256));

        if (mocMarkup > 0) {
            return 0;
        }

        return btcCommission + btcMarkup;
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

}
