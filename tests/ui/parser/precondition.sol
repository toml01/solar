// fhec fork patch: `precondition { ... }` is a contextual keyword of the `.fsol` dialect.
// It parses in any statement position; legality of the position is checked downstream by fhec.
contract Precondition {
    uint256 precondition;

    function f(uint256 a) public returns (uint256 b) {
        precondition {
            b = a;
        }
        {
            precondition {
                b = a + 1;
            }
        }
    }

    // `precondition` is not a reserved word.
    function g(uint256 x) public view returns (uint256) {
        return precondition + x;
    }
}

// A callable named `precondition` still takes call options: `f{gas: g, value: v}(...)` is the one
// plain Solidity statement that starts with `identifier {`.
contract PreconditionCallOptions {
    function() external payable precondition;

    function f() public {
        precondition{value: 1}();
    }
}

contract PreconditionCallOptionsWithArgs {
    function(uint256, uint256) external payable precondition;

    function f(uint256 g, uint256 v, uint256 x, uint256 y) public {
        precondition{gas: g, value: v}(x, y);
    }
}
