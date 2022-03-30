// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IUniswapV1Factory {
  function initializeFactory ( address template ) external;
  function createExchange ( address token ) external returns ( address );
  function getExchange ( address token ) external returns ( address );
  function getToken ( address exchange ) external returns ( address );
  function getTokenWithId ( uint256 token_id ) external returns ( address );
  function exchangeTemplate (  ) external returns ( address );
  function tokenCount (  ) external returns ( uint256 );
}
