// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IUniswapV1Exchange {
function setup ( address token_addr ) external;
  function addLiquidity ( uint256 min_liquidity, uint256 max_tokens, uint256 deadline ) external payable returns ( uint256 );
  function removeLiquidity ( uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline ) external returns ( uint256, uint256 );
  function __default__ (  ) external payable;
  function ethToTokenSwapInput ( uint256 min_tokens, uint256 deadline ) external payable returns ( uint256 );
  function ethToTokenTransferInput ( uint256 min_tokens, uint256 deadline, address recipient ) external payable returns ( uint256 );
  function ethToTokenSwapOutput ( uint256 tokens_bought, uint256 deadline ) external payable returns ( uint256 );
  function ethToTokenTransferOutput ( uint256 tokens_bought, uint256 deadline, address recipient ) external payable returns ( uint256 );
  function tokenToEthSwapInput ( uint256 tokens_sold, uint256 min_eth, uint256 deadline ) external returns ( uint256 );
  function tokenToEthTransferInput ( uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient ) external returns ( uint256 );
  function tokenToEthSwapOutput ( uint256 eth_bought, uint256 max_tokens, uint256 deadline ) external returns ( uint256 );
  function tokenToEthTransferOutput ( uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient ) external returns ( uint256 );
  function tokenToTokenSwapInput ( uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr ) external returns ( uint256 );
  function tokenToTokenTransferInput ( uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr ) external returns ( uint256 );
  function tokenToTokenSwapOutput ( uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr ) external returns ( uint256 );
  function tokenToTokenTransferOutput ( uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr ) external returns ( uint256 );
  function tokenToExchangeSwapInput ( uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr ) external returns ( uint256 );
  function tokenToExchangeTransferInput ( uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr ) external returns ( uint256 );
  function tokenToExchangeSwapOutput ( uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr ) external returns ( uint256 );
  function tokenToExchangeTransferOutput ( uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr ) external returns ( uint256 );
  function getEthToTokenInputPrice ( uint256 eth_sold ) external returns ( uint256 );
  function getEthToTokenOutputPrice ( uint256 tokens_bought ) external returns ( uint256 );
  function getTokenToEthInputPrice ( uint256 tokens_sold ) external returns ( uint256 );
  function getTokenToEthOutputPrice ( uint256 eth_bought ) external returns ( uint256 );
  function tokenAddress (  ) external returns ( address );
  function factoryAddress (  ) external returns ( address );
  function balanceOf ( address _owner ) external returns ( uint256 );
  function transfer ( address _to, uint256 _value ) external returns ( bool );
  function transferFrom ( address _from, address _to, uint256 _value ) external returns ( bool );
  function approve ( address _spender, uint256 _value ) external returns ( bool );
  function allowance ( address _owner, address _spender ) external returns ( uint256 );
  function name (  ) external returns ( bytes32 );
  function symbol (  ) external returns ( bytes32 );
  function decimals (  ) external returns ( uint256 );
  function totalSupply (  ) external returns ( uint256 );
}
