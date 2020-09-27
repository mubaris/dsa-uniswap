pragma solidity ^0.6.0;

// import files from common directory
import { TokenInterface , MemoryInterface, EventInterface} from "../common/interfaces.sol";
import { Stores } from "../common/stores.sol";
import { DSMath } from "../common/math.sol";

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract UniswapHelpers is Stores, DSMath {

    // /**
    //  * @dev -- Mubaris
    //  */
    // function connectorID() public pure returns(uint _type, uint _id) {
    //     (_type, _id) = (1, 3);
    // }

    /**
     * @dev Return WETH address
     */
    function getAddressWETH() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    /**
     * @dev Return USDT address -- Mubaris
     */
    function getAddressUSDT() internal pure returns (address) {
        return 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    }

    /**
     * @dev Return USDC address -- Mubaris
     */
    function getAddressUSDC() internal pure returns (address) {
        return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }

    /**
     * @dev Return DAI address -- Mubaris
     */
    function getAddressDAI() internal pure returns (address) {
        return 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    }

    /**
     * @dev Return WBTC address -- Mubaris
     */
    function getAddressWBTC() internal pure returns (address) {
        return 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    }

    /**
     * @dev Return uniswap v2 router02 Address
     */
    function getUniswapAddr() internal pure returns (address) {
        return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    }

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBalace(address token) internal view returns (uint256 amt) {
        amt = token == getEthAddr() ? address(this).balance : TokenInterface(token).balanceOf(address(this));
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(buy);
        _sell = sell == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(sell);
    }

    function convertEthToWeth(TokenInterface token, uint amount) internal {
        if(address(token) == getAddressWETH()) token.deposit.value(amount)();
    }

    function convertWethToEth(TokenInterface token, uint amount) internal {
       if(address(token) == getAddressWETH()) {
            token.approve(getAddressWETH(), amount);
            token.withdraw(amount);
        }
    }

    function getExpectedBuyAmt(
        IUniswapV2Router02 router,
        address[] memory paths,
        uint sellAmt
    ) internal view returns(uint buyAmt) {
        uint[] memory amts = router.getAmountsOut(
            sellAmt,
            paths
        );
        buyAmt = amts[1];
    }

    function getExpectedSellAmt(
        IUniswapV2Router02 router,
        address[] memory paths,
        uint buyAmt
    ) internal view returns(uint sellAmt) {
        uint[] memory amts = router.getAmountsIn(
            buyAmt,
            paths
        );
        sellAmt = amts[0];
    }

    function checkPair(
        IUniswapV2Router02 router,
        address[] memory paths
    ) internal view {
        address pair = IUniswapV2Factory(router.factory()).getPair(paths[0], paths[1]);
        require(pair != address(0), "No-exchange-address");
    }

    function getPaths(
        address buyAddr,
        address sellAddr
    ) internal pure returns(address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
    }

    /**
     * @dev -- Mubaris
     */
    function checkPaths(
        IUniswapV2Router02 router,
        address[] memory paths
    ) internal view {
        for (uint i; i < paths.length - 1; i++) {
            address pair = IUniswapV2Factory(router.factory()).getPair(paths[i], paths[i + 1]);
            require(pair != address(0), "No-exchange-address");
        }
    }

    /**
     * @dev -- Mubaris
     */
    function getExpectedBuyAmtNormalized(
        IUniswapV2Router02 router,
        address[] memory paths,
        uint sellAmt
    ) internal view returns(uint) {
        for (uint i; i < paths.length - 1; i++) {
            if (paths[i] == paths[i + 1]) {
                return 0;
            }
        }
        return getExpectedBuyAmt(router, paths, sellAmt);
    }

    /**
     * @dev -- Mubaris
     */
    function getExpectedSellAmtNormalized(
        IUniswapV2Router02 router,
        address[] memory paths,
        uint buyAmt
    ) internal view returns(uint) {
        for (uint i; i < paths.length - 1; i++) {
            if (paths[i] == paths[i + 1]) {
                return uint(-1);
            }
        }
        return getExpectedSellAmt(router, paths, buyAmt);
    }

    /**
     * @dev -- Mubaris
     */
    function getOptimalSellPaths(
        address buyAddr,
        address sellAddr,
        uint sellAmt
    ) public view returns(address[] memory paths, uint buyAmt) {
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());

        if (sellAddr == getEthAddr()) {
            sellAddr = getAddressWETH();
        }

        if (buyAddr == getEthAddr()) {
            buyAddr = getAddressWETH();
        }
        
        address[] memory _path = new address[](2);
        _path[0] = address(sellAddr);
        _path[1] = address(buyAddr);

        uint _buyAmt = getExpectedBuyAmtNormalized(router, _path, sellAmt);

        paths = _path;
        buyAmt = _buyAmt;

        delete _path;

        /* Path via ETH */
        _path = new address[](3);
        _path[0] = address(sellAddr);
        _path[1] = getAddressWETH();
        _path[2] = address(buyAddr);

        _buyAmt = getExpectedBuyAmtNormalized(router, _path, sellAmt);

        if (_buyAmt > buyAmt) {
            buyAmt = _buyAmt;
            paths = _path;
        }

        /* Path via USDT */
        // address[] memory path2 = new address[](3);
        // path2[0] = address(sellAddr);
        _path[1] = getAddressUSDT();
        // path2[2] = address(buyAddr);

        _buyAmt = getExpectedBuyAmtNormalized(router, _path, sellAmt);

        if (_buyAmt > buyAmt) {
            buyAmt = _buyAmt;
            paths = _path;
        }

        /* Path via USDC */
        // address[] memory path3 = new address[](3);
        // path3[0] = address(sellAddr);
        _path[1] = getAddressUSDC();
        // path3[2] = address(buyAddr);

        _buyAmt = getExpectedBuyAmtNormalized(router, _path, sellAmt);

        if (_buyAmt > buyAmt) {
            buyAmt = _buyAmt;
            paths = _path;
        }

        /* Path via DAI */
        // address[] memory path4 = new address[](3);
        // path4[0] = address(sellAddr);
        _path[1] = getAddressDAI();
        // path4[2] = address(buyAddr);

        _buyAmt = getExpectedBuyAmtNormalized(router, _path, sellAmt);

        if (_buyAmt > buyAmt) {
            buyAmt = _buyAmt;
            paths = _path;
        }

        // /* Path via USDT-USDC */
        // address[] memory path5 = new address[](4);
        // path5[0] = address(sellAddr);
        // path5[1] = getAddressUSDT();
        // path5[2] = getAddressUSDC();
        // path5[3] = address(buyAddr);

        // uint buyAmt5 = getExpectedBuyAmtNormalized(router, path5, sellAmt);

        // if (buyAmt5 > buyAmt) {
        //     buyAmt = buyAmt5;
        //     paths = path5;
        // }

        // /* Path via USDC-USDT */
        // address[] memory path6 = new address[](4);
        // path6[0] = address(sellAddr);
        // path6[1] = getAddressUSDC();
        // path6[2] = getAddressUSDT();
        // path6[3] = address(buyAddr);

        // uint buyAmt6 = getExpectedBuyAmtNormalized(router, path6, sellAmt);

        // if (buyAmt6 > buyAmt) {
        //     buyAmt = buyAmt6;
        //     paths = path6;
        // }

        // /* Path via USDC-DAI */
        // address[] memory path7 = new address[](4);
        // path7[0] = address(sellAddr);
        // path7[1] = getAddressUSDC();
        // path7[2] = getAddressDAI();
        // path7[3] = address(buyAddr);

        // uint buyAmt7 = getExpectedBuyAmtNormalized(router, path7, sellAmt);

        // if (buyAmt7 > buyAmt) {
        //     buyAmt = buyAmt7;
        //     paths = path7;
        // }

        // /* Path via DAI-USDC */
        // address[] memory path8 = new address[](4);
        // path8[0] = address(sellAddr);
        // path8[1] = getAddressDAI();
        // path8[2] = getAddressUSDC();
        // path8[3] = address(buyAddr);

        // uint buyAmt8 = getExpectedBuyAmtNormalized(router, path8, sellAmt);

        // if (buyAmt8 > buyAmt) {
        //     buyAmt = buyAmt8;
        //     paths = path8;
        // }

        return (paths, buyAmt);
    }

    /**
     * @dev -- Mubaris
     */
    function getOptimalBuyPaths(
        address buyAddr,
        address sellAddr,
        uint buyAmt
    ) public view returns(address[] memory paths, uint sellAmt) {
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());

        if (sellAddr == getEthAddr()) {
            sellAddr = getAddressWETH();
        }

        if (buyAddr == getEthAddr()) {
            buyAddr = getAddressWETH();
        }

        address[] memory _path = new address[](2);
        _path[0] = address(sellAddr);
        _path[1] = address(buyAddr);

        uint _sellAmt = getExpectedSellAmtNormalized(router, _path, buyAmt);

        paths = _path;
        sellAmt = _sellAmt;

        delete _path;

        /* Path via ETH */
        _path = new address[](3);
        _path[0] = address(sellAddr);
        _path[1] = getAddressWETH();
        _path[2] = address(buyAddr);

        _sellAmt = getExpectedSellAmtNormalized(router, _path, buyAmt);

        if (_sellAmt < sellAmt) {
            sellAmt = _sellAmt;
            paths = _path;
        }

        /* Path via USDT */
        // address[] memory _path = new address[](3);
        // _path[0] = address(sellAddr);
        _path[1] = getAddressUSDT();
        // path2[2] = address(buyAddr);

        _sellAmt = getExpectedSellAmtNormalized(router, _path, buyAmt);

        if (_sellAmt < sellAmt) {
            sellAmt = _sellAmt;
            paths = _path;
        }

        /* Path via USDC */
        // address[] memory path3 = new address[](3);
        // path3[0] = address(sellAddr);
        _path[1] = getAddressUSDC();
        // path3[2] = address(buyAddr);

        _sellAmt = getExpectedSellAmtNormalized(router, _path, buyAmt);

        if (_sellAmt < sellAmt) {
            sellAmt = _sellAmt;
            paths = _path;
        }

        /* Path via DAI */
        // address[] memory path4 = new address[](3);
        // path4[0] = address(sellAddr);
        _path[1] = getAddressDAI();
        // path4[2] = address(buyAddr);

        _sellAmt = getExpectedSellAmtNormalized(router, _path, buyAmt);

        if (_sellAmt < sellAmt) {
            sellAmt = _sellAmt;
            paths = _path;
        }

        // /* Path via USDT-USDC */
        // address[] memory path5 = new address[](4);
        // path5[0] = address(sellAddr);
        // path5[1] = getAddressUSDT();
        // path5[2] = getAddressUSDC();
        // path5[3] = address(buyAddr);

        // uint sellAmt5 = getExpectedSellAmtNormalized(router, path5, buyAmt);

        // if (sellAmt5 < sellAmt) {
        //     sellAmt = sellAmt5;
        //     paths = path5;
        // }

        // /* Path via USDC-USDT */
        // address[] memory path6 = new address[](4);
        // path6[0] = address(sellAddr);
        // path6[1] = getAddressUSDC();
        // path6[2] = getAddressUSDT();
        // path6[3] = address(buyAddr);

        // uint sellAmt6 = getExpectedSellAmtNormalized(router, path6, buyAmt);

        // if (sellAmt6 < sellAmt) {
        //     sellAmt = sellAmt6;
        //     paths = path6;
        // }

        // /* Path via USDC-DAI */
        // address[] memory path7 = new address[](4);
        // path7[0] = address(sellAddr);
        // path7[1] = getAddressUSDC();
        // path7[2] = getAddressDAI();
        // path7[3] = address(buyAddr);

        // uint sellAmt7 = getExpectedSellAmtNormalized(router, path7, buyAmt);

        // if (sellAmt7 < sellAmt) {
        //     sellAmt = sellAmt7;
        //     paths = path7;
        // }

        // /* Path via DAI-USDC */
        // address[] memory path8 = new address[](4);
        // path8[0] = address(sellAddr);
        // path8[1] = getAddressDAI();
        // path8[2] = getAddressUSDC();
        // path8[3] = address(buyAddr);

        // uint sellAmt8 = getExpectedSellAmtNormalized(router, path8, buyAmt);

        // if (sellAmt8 < sellAmt) {
        //     sellAmt = sellAmt8;
        //     paths = path8;
        // }

        return (paths, sellAmt);
    }
}

contract LiquidityHelpers is UniswapHelpers {

    function getMinAmount(
        TokenInterface token,
        uint amt,
        uint slippage
    ) internal view returns(uint minAmt) {
        uint _amt18 = convertTo18(token.decimals(), amt);
        minAmt = wmul(_amt18, sub(WAD, slippage));
        minAmt = convert18ToDec(token.decimals(), minAmt);
    }

    function changeEthToWeth(
        address[] memory tokens
    ) internal pure returns(TokenInterface[] memory _tokens) {
        _tokens = new TokenInterface[](2);
        _tokens[0] = tokens[0] == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(tokens[0]);
        _tokens[1] = tokens[1] == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(tokens[1]);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint _amt,
        uint unitAmt,
        uint slippage
    ) internal returns (uint _amtA, uint _amtB, uint _liquidity) {
        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);

        _amtA = _amt == uint(-1) ? getTokenBalace(tokenA) : _amt;
        _amtB = convert18ToDec(_tokenB.decimals(), wmul(unitAmt, convertTo18(_tokenA.decimals(), _amtA)));

        convertEthToWeth(_tokenA, _amtA);
        convertEthToWeth(_tokenB, _amtB);
        _tokenA.approve(address(router), _amtA);
        _tokenB.approve(address(router), _amtB);

       uint minAmtA = getMinAmount(_tokenA, _amtA, slippage);
        uint minAmtB = getMinAmount(_tokenB, _amtB, slippage);
       (_amtA, _amtB, _liquidity) = router.addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _amtA,
            _amtB,
            minAmtA,
            minAmtB,
            address(this),
            now + 1
        );
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint _amt,
        uint unitAmtA,
        uint unitAmtB
    ) internal returns (uint _amtA, uint _amtB, uint _uniAmt) {
        IUniswapV2Router02 router;
        TokenInterface _tokenA;
        TokenInterface _tokenB;
        (router, _tokenA, _tokenB, _uniAmt) = _getRemoveLiquidityData(
            tokenA,
            tokenB,
            _amt
        );
        {
        uint minAmtA = convert18ToDec(_tokenA.decimals(), wmul(unitAmtA, _uniAmt));
        uint minAmtB = convert18ToDec(_tokenB.decimals(), wmul(unitAmtB, _uniAmt));
        (_amtA, _amtB) = router.removeLiquidity(
            address(_tokenA),
            address(_tokenB),
            _uniAmt,
            minAmtA,
            minAmtB,
            address(this),
            now + 1
        );
        }
        convertWethToEth(_tokenA, _amtA);
        convertWethToEth(_tokenB, _amtB);
    }

    function _getRemoveLiquidityData(
        address tokenA,
        address tokenB,
        uint _amt
    ) internal returns (IUniswapV2Router02 router, TokenInterface _tokenA, TokenInterface _tokenB, uint _uniAmt) {
        router = IUniswapV2Router02(getUniswapAddr());
        (_tokenA, _tokenB) = changeEthAddress(tokenA, tokenB);
        address exchangeAddr = IUniswapV2Factory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr != address(0), "pair-not-found.");

        TokenInterface uniToken = TokenInterface(exchangeAddr);
        _uniAmt = _amt == uint(-1) ? uniToken.balanceOf(address(this)) : _amt;
        uniToken.approve(address(router), _uniAmt);
    }
}

contract UniswapLiquidity is LiquidityHelpers {
    event LogDepositLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint amtA,
        uint amtB,
        uint uniAmount,
        uint getId,
        uint setId
    );

    event LogWithdrawLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint amountA,
        uint amountB,
        uint uniAmount,
        uint getId,
        uint[] setId
    );

    function emitDeposit(
        address tokenA,
        address tokenB,
        uint _amtA,
        uint _amtB,
        uint _uniAmt,
        uint getId,
        uint setId
    ) internal {
        emit LogDepositLiquidity(
            tokenA,
            tokenB,
            _amtA,
            _amtB,
            _uniAmt,
            getId,
            setId
        );

        bytes32 _eventCode = keccak256("LogDepositLiquidity(address,address,uint256,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(
            tokenA,
            tokenB,
            _amtA,
            _amtB,
            _uniAmt,
            getId,
            setId
        );
        emitEvent(_eventCode, _eventParam);
    }

    function emitWithdraw(
        address tokenA,
        address tokenB,
        uint _amtA,
        uint _amtB,
        uint _uniAmt,
        uint getId,
        uint[] memory setIds
    ) internal {
        emit LogWithdrawLiquidity(
            tokenA,
            tokenB,
            _amtA,
            _amtB,
            _uniAmt,
            getId,
            setIds
        );
        bytes32 _eventCode = keccak256("LogWithdrawLiquidity(address,address,uint256,uint256,uint256,uint256,uint256[])");
        bytes memory _eventParam = abi.encode(
            tokenA,
            tokenB,
            _amtA,
            _amtB,
            _uniAmt,
            getId,
            setIds
        );
        emitEvent(_eventCode, _eventParam);
    }

    /**
     * @dev Deposit Liquidity.
     * @param tokenA tokenA address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param tokenB tokenB address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amtA tokenA amount.
     * @param unitAmt unit amount of amtB/amtA with slippage.
     * @param slippage slippage amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function deposit(
        address tokenA,
        address tokenB,
        uint amtA,
        uint unitAmt,
        uint slippage,
        uint getId,
        uint setId
    ) external payable {
        uint _amt = getUint(getId, amtA);

        (uint _amtA, uint _amtB, uint _uniAmt) = _addLiquidity(
                                            tokenA,
                                            tokenB,
                                            _amt,
                                            unitAmt,
                                            slippage
                                            );
        setUint(setId, _uniAmt);
        emitDeposit(tokenA, tokenB, _amtA, _amtB, _uniAmt, getId, setId);
    }

    /**
     * @dev Withdraw Liquidity.
     * @param tokenA tokenA address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param tokenB tokenB address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param uniAmt uni token amount.
     * @param unitAmtA unit amount of amtA/uniAmt with slippage.
     * @param unitAmtB unit amount of amtB/uniAmt with slippage.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setIds Set token amounts at this IDs in `InstaMemory` Contract.
    */
    function withdraw(
        address tokenA,
        address tokenB,
        uint uniAmt,
        uint unitAmtA,
        uint unitAmtB,
        uint getId,
        uint[] calldata setIds
    ) external payable {
        uint _amt = getUint(getId, uniAmt);

        (uint _amtA, uint _amtB, uint _uniAmt) = _removeLiquidity(
            tokenA,
            tokenB,
            _amt,
            unitAmtA,
            unitAmtB
        );

        setUint(setIds[0], _amtA);
        setUint(setIds[1], _amtB);
        emitWithdraw(tokenA, tokenB, _amtA, _amtB, _uniAmt, getId, setIds);
    }
}

contract UniswapResolver is UniswapLiquidity {
    event LogBuy(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    event LogSell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    /**
     * @dev Buy ETH/ERC20_Token.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param buyAmt buying token amount.
     * @param unitAmt unit amount of sellAmt/buyAmt with slippage.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function buy(
        address buyAddr,
        address sellAddr,
        uint buyAmt,
        uint unitAmt,
        uint getId,
        uint setId
    ) external payable {
        uint _buyAmt = getUint(getId, buyAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        address[] memory paths = getPaths(address(_buyAddr), address(_sellAddr));

        uint _slippageAmt = convert18ToDec(_sellAddr.decimals(),
            wmul(unitAmt, convertTo18(_buyAddr.decimals(), _buyAmt)));

        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());

        checkPair(router, paths);
        uint _expectedAmt = getExpectedSellAmt(router, paths, _buyAmt);
        require(_slippageAmt >= _expectedAmt, "Too much slippage");

        convertEthToWeth(_sellAddr, _expectedAmt);
        _sellAddr.approve(address(router), _expectedAmt);

        uint _sellAmt = router.swapTokensForExactTokens(
            _buyAmt,
            _expectedAmt,
            paths,
            address(this),
            now + 1
        )[0];

        convertWethToEth(_buyAddr, _buyAmt);

        setUint(setId, _sellAmt);

        emit LogBuy(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        bytes32 _eventCode = keccak256("LogBuy(address,address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Sell ETH/ERC20_Token.
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sell(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        uint getId,
        uint setId
    ) external payable {
        uint _sellAmt = getUint(getId, sellAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        address[] memory paths = getPaths(address(_buyAddr), address(_sellAddr));

        if (_sellAmt == uint(-1)) {
            _sellAmt = sellAddr == getEthAddr() ? address(this).balance : _sellAddr.balanceOf(address(this));
        }

        uint _slippageAmt = convert18ToDec(_buyAddr.decimals(),
            wmul(unitAmt, convertTo18(_sellAddr.decimals(), _sellAmt)));

        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());

        checkPair(router, paths);
        uint _expectedAmt = getExpectedBuyAmt(router, paths, _sellAmt);
        require(_slippageAmt <= _expectedAmt, "Too much slippage");

        convertEthToWeth(_sellAddr, _sellAmt);
        _sellAddr.approve(address(router), _sellAmt);

        uint _buyAmt = router.swapExactTokensForTokens(
            _sellAmt,
            _expectedAmt,
            paths,
            address(this),
            now + 1
        )[1];

        convertWethToEth(_buyAddr, _buyAmt);

        setUint(setId, _buyAmt);

        emit LogSell(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        bytes32 _eventCode = keccak256("LogSell(address,address,uint256,uint256,uint256,uint256)");
        bytes memory _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Buy ETH/ERC20_Token. -- Mubaris
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param buyAmt buying token amount.
     * @param unitAmt unit amount of sellAmt/buyAmt with slippage.
     * @param paths Uniswap Path for the swap.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function buyNormalized(
        address buyAddr,
        address sellAddr,
        uint buyAmt,
        uint unitAmt,
        address[] calldata paths,
        uint getId,
        uint setId
    ) external payable {
        uint _buyAmt = getUint(getId, buyAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);

        uint _slippageAmt = convert18ToDec(_sellAddr.decimals(),
            wmul(unitAmt, convertTo18(_buyAddr.decimals(), _buyAmt)));

        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());

        checkPaths(router, paths);
        uint _expectedAmt = getExpectedSellAmtNormalized(router, paths, _buyAmt);
        require(_slippageAmt >= _expectedAmt, "Too much slippage");

        convertEthToWeth(_sellAddr, _expectedAmt);
        _sellAddr.approve(address(router), _expectedAmt);

        uint _sellAmt = router.swapTokensForExactTokens(
            _buyAmt,
            _expectedAmt,
            paths,
            address(this),
            now + 1
        )[0];

        convertWethToEth(_buyAddr, _buyAmt);

        setUint(setId, _sellAmt);

        // emit LogBuy(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        // bytes32 _eventCode = keccak256("LogBuy(address,address,uint256,uint256,uint256,uint256)");
        // bytes memory _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        // (uint _type, uint _id) = connectorID();
        // EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Sell ETH/ERC20_Token. -- Mubaris
     * @param buyAddr buying token address.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr selling token amount.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt selling token amount.
     * @param unitAmt unit amount of buyAmt/sellAmt with slippage.
     * @param paths Uniswap Path for the swap.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function sellNormalized(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        address[] calldata paths,
        uint getId,
        uint setId
    ) external payable {
        uint _sellAmt = getUint(getId, sellAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);

        if (_sellAmt == uint(-1)) {
            _sellAmt = sellAddr == getEthAddr() ? address(this).balance : _sellAddr.balanceOf(address(this));
        }

        uint _slippageAmt = convert18ToDec(_buyAddr.decimals(),
            wmul(unitAmt, convertTo18(_sellAddr.decimals(), _sellAmt)));

        IUniswapV2Router02 router = IUniswapV2Router02(getUniswapAddr());

        checkPaths(router, paths);
        uint _expectedAmt = getExpectedBuyAmtNormalized(router, paths, _sellAmt);
        require(_slippageAmt <= _expectedAmt, "Too much slippage");

        convertEthToWeth(_sellAddr, _sellAmt);
        _sellAddr.approve(address(router), _sellAmt);

        uint _buyAmt = router.swapExactTokensForTokens(
            _sellAmt,
            _expectedAmt,
            paths,
            address(this),
            now + 1
        )[1];

        convertWethToEth(_buyAddr, _buyAmt);

        setUint(setId, _buyAmt);

        // emit LogSell(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        // bytes32 _eventCode = keccak256("LogSell(address,address,uint256,uint256,uint256,uint256)");
        // bytes memory _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
        // (uint _type, uint _id) = connectorID();
        // EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }
}


contract ConnectUniswapV2 is UniswapResolver {
    string public name = "UniswapV2-v1";
}