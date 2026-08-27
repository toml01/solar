// fhec fork patch: the shared-boundary marker of the `.fsol` dialect. This parser only
// records the marker; legality is checked by fhec.
contract Shared {
    // Input side: a bare `shared` between the `in` sugar and the type.
    function input(in shared uint256 amount) public pure returns (uint256) {
        return amount;
    }

    // The `in(proof)` binder and the marker compose.
    function inputWithProof(in(p) shared uint256 amount, bytes calldata p)
        public
        pure
        returns (uint256)
    {
        return amount + p.length;
    }

    // Output side: a recipient in the type position of a return.
    function output(uint256 a) public view returns (shared(msg.sender) uint256) {
        return a;
    }

    // Named returns work the same.
    function namedOutput(uint256 a) public view returns (shared(msg.sender) uint256 out) {
        out = a;
    }

    // Recorded, not judged, in the other declaration positions too.
    event Deposit(shared(msg.sender) uint256 amount);

    error BadOutput(in shared uint256 amount);

    shared(msg.sender) uint256 public balance;

    // `shared` stays an ordinary identifier everywhere else.
    uint256 internal shared;

    function shared_(uint256 shared) public pure returns (uint256 shared__) {
        shared__ = shared;
    }
}
