// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./BaseIlluvitar.sol";
import "./DataTypes.sol";

/**
 * @title Portrait Layer
 * @dev inherit BaseIlluvitar
 * @author Dmitry Yakovlevich
 */
contract PortraitLayer is BaseIlluvitar {
    /// @dev Portrait Metadata struct
    struct Metadata {
        BoxType boxType; // box type
        uint8 tier; // tier
        // Bonded accessory token ids
        uint256 skinId; // bonded skin id
        uint256 bodyId; // bonded body id
        uint256 eyeId; // bonded eye wear id
        uint256 headId; // bonded head wear id
        uint256 propsId; // bonded props id
    }

    /// @dev Portrait metadata
    mapping(uint256 => Metadata) public metadata;

    /**
     * @dev Initialize Portrait Layer.
     * @param name_ NFT Name
     * @param symbol_ NFT Symbol
     * @param imxMinter_ IMX Minter Address
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address imxMinter_
    ) external initializer {
        __BaseIlluvitar_init(name_, symbol_, imxMinter_);
    }

    /**
     * @dev Mint Portrait with blueprint.
     * @dev blueprint has format of `ab,c,d,e,f,g`
     *      a : box type
            b : tier
            c : bonded skin id
            d : bonded body id
            e : bonded eye wear id
            f : bonded head wear id
            g : bonded props id
     * @param to Recipient address
     * @param tokenId Token id
     * @param blueprint Portrait blueprint
     */
    function _mint(
        address to,
        uint256 tokenId,
        bytes memory blueprint
    ) internal override {
        _safeMint(to, tokenId);
        if (!metadataInitialized[tokenId]) {
            (
                BoxType boxType,
                uint8 tier,
                uint256 skinTokenId,
                uint256 bodyTokenId,
                uint256 eyeTokenId,
                uint256 headTokenId,
                uint256 propsTokenId
            ) = _parseBlueprint(blueprint);
            metadata[tokenId] = Metadata({
                boxType: boxType,
                tier: tier,
                skinId: skinTokenId,
                bodyId: bodyTokenId,
                eyeId: eyeTokenId,
                headId: headTokenId,
                propsId: propsTokenId
            });
            metadataInitialized[tokenId] = true;
        }
    }

    /// @dev Parse blueprint
    function _parseBlueprint(bytes memory blueprint)
        private
        pure
        returns (
            BoxType boxType,
            uint8 tier,
            uint256 skinTokenId,
            uint256 bodyTokenId,
            uint256 eyeTokenId,
            uint256 headTokenId,
            uint256 propsTokenId
        )
    {
        uint8 j = 0;

        uint256 len = blueprint.length;
        uint8 p;
        for (; p < len; p += 1) {
            if (_isDecimal(blueprint[p])) {
                if (j == 0) {
                    boxType = BoxType(uint8(blueprint[p]) - 0x30);
                } else if (j == 1) {
                    tier = uint8(blueprint[p]) - 0x30;
                    p += 1;
                    break;
                }
                j += 1;
            }
        }

        (skinTokenId, p) = _atoi(blueprint, p);
        (bodyTokenId, p) = _atoi(blueprint, p);
        (eyeTokenId, p) = _atoi(blueprint, p);
        (headTokenId, p) = _atoi(blueprint, p);
        (propsTokenId, p) = _atoi(blueprint, p);
    }

    /**
     * @dev Simplified version of StringUtils.atoi to convert a bytes string
     *      to unsigned integer using ten as a base
     * @dev Stops on invalid input (wrong character for base ten) and returns
     *      the position within a string where the wrong character was encountered
     *
     * @dev Throws if input string contains a number bigger than uint256
     *
     * @param a numeric string to convert
     * @param offset an index to start parsing from, set to zero to parse from the beginning
     * @return i a number representing given string
     * @return p an index where the conversion stopped
     */
    function _atoi(bytes memory a, uint8 offset) internal pure returns (uint256 i, uint8 p) {
        // skip wrong characters in the beginning of the string if any
        for (p = offset; p < a.length; p++) {
            // check if digit is valid and meets the base 10
            if (_isDecimal(a[p])) {
                // we've found decimal character, skipping stops
                break;
            }
        }

        // if there weren't any digits found
        if (p == a.length) {
            // just return a zero result
            return (0, offset);
        }

        // iterate over the rest of the string (bytes buffer)
        for (; p < a.length; p++) {
            // check if digit is valid and meets the base 10
            if (!_isDecimal(a[p])) {
                // we've found bad character, parsing stops
                break;
            }

            // move to the next digit slot
            i *= 10;

            // extract the digit and add it to the result
            i += uint8(a[p]) - 0x30;
        }

        // return the result
        return (i, p);
    }
}
