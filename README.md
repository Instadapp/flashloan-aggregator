# flashloan-aggregator
Flashloan aggregator on all major chains.

### Contracts
User will interact with flashloan aggregator contract which handles all the other interaction with other flashloans. User specifies the route which is then used to fetch the flashloan provider. Eg:- route = 1 could be Aave's flashloan, route 2 could be MakerDAO's flashloan, etc.
- At once user can select only one particular route even for borrowing multiple tokens.
- User needs to calculate the route off-chain to see the best route for their tokens (flashloan fee & tokens liquidity).
- Flashloan aggregator will handle all the reverse calls from flashloan contracts in order to execute the code.

For the basic idea to get started. Here is theour current [flashloan contract](https://github.com/Instadapp/dsa-flashloan/blob/Flashloan-Aave-update/contracts/flashloan/Instapool%20v2/main.sol)

Need to follow somewhat similar method.