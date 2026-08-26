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
