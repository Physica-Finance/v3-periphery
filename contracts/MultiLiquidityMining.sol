// SPDX-License-Identifier: MIT
/*pragma solidity ^0.8.24;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract MultiLiquidityMining is IERC721Receiver {

    int24 private constant MIN_TICK = -887272;
    int24 private constant MAX_TICK = -MIN_TICK;
    int24 private constant TICK_SPACING = 60;

    INonfungiblePositionManager public nonfungiblePositionManager =
    INonfungiblePositionManager(0xD119534C876320dd92F69ae54B35b56A9a4E139b);

    address token0Address;
    address token0SenderAddress;

    address constant wplqAddress = "0x5EBCdf1De1781e8B5D41c016B0574aD53E2F6E1A"; // WPLQ
    address wplqAddressSenderAddress;

    IERC20 private token0i;
    IWETH private WPLQi;

    modifier onlyOwner {
        require(msg.sender == wplqAddressSenderAddress || msg.sender == token0SenderAddress);
        _;
    }

    constructor(address token0Addr, address token0Sender){
        token0Address = token0Addr;
        token0SenderAddress = token0Sender;
        token0i = IERC20(token0Address);
        WPLQi = IWETH(wplqAddress);
        wplqAddressSenderAddress = msg.sender;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function mintNewPosition(uint256 amount0ToAdd, uint256 amount1ToAdd)
    external onlyOwner
    returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    )
    {
        token0i.approve(address(nonfungiblePositionManager), amount0ToAdd);
        WPLQi.approve(address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.MintParams memory params =
                            INonfungiblePositionManager.MintParams({
                token0: token0Address,
                token1: wplqAddress,
                fee: 3000,
                tickLower: (MIN_TICK / TICK_SPACING) * TICK_SPACING,
                tickUpper: (MAX_TICK / TICK_SPACING) * TICK_SPACING,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) =
        nonfungiblePositionManager.mint(params);
    }

    function withdraw() external onlyOwner {
        token0i.approve(address(nonfungiblePositionManager), 0);
        uint256 refund0 = token0i.balanceOf(address(this));
        if (refund0 > 0) {
            token0i.transfer(token0SenderAddress, refund0);
        }

        WPLQi.approve(address(nonfungiblePositionManager), 0);
        uint256 refund1 = WPLQi.balanceOf(address(this));
        if (refund1 > 0) {
            WPLQi.transfer(wplqAddressSenderAddress, refund1);
        }
    }

    function collectAllFees(uint256 tokenId)
    external onlyOwner
    returns (uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.CollectParams memory params =
                            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);
    }

    function increaseLiquidityCurrentRange(
        uint256 tokenId,
        uint256 amount0ToAdd,
        uint256 amount1ToAdd
    ) external onlyOwner returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        token0i.approve(address(nonfungiblePositionManager), amount0ToAdd);
        WPLQi.approve(address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.IncreaseLiquidityParams memory params =
                            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (liquidity, amount0, amount1) =
        nonfungiblePositionManager.increaseLiquidity(params);
    }

    function decreaseLiquidityCurrentRange(uint256 tokenId, uint128 liquidity)
    external onlyOwner
    returns (uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.DecreaseLiquidityParams memory params =
                            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (amount0, amount1) =
        nonfungiblePositionManager.decreaseLiquidity(params);
    }
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(MintParams calldata params)
    external
    payable
    returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
    external
    returns (bool);
    function allowance(address owner, address spender)
    external
    view
    returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
    external
    returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}
*/
