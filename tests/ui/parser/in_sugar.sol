// fhec fork patch: `in` parameter sugar of the `.fsol` dialect, with the optional
// `in(proof)` binder. This parser only records the marker; legality is checked by fhec.
contract InSugar {
    // Implicit form: no binder.
    function implicit(in uint256 amount) public pure returns (uint256) {
        return amount;
    }

    // Explicit form: the binder names the proof parameter.
    function explicit(in(inputProof) uint256 amount, bytes calldata inputProof)
        public
        pure
        returns (uint256)
    {
        return amount + inputProof.length;
    }

    // The binder is whitespace-insensitive: no type starts with `(`.
    function spaced(in (inputProof) uint256 amount, bytes calldata inputProof)
        public
        pure
        returns (uint256)
    {
        return amount + inputProof.length;
    }

    // Mixing the two forms is fhec's problem, not this parser's.
    function mixed(in uint256 a, in(p) uint256 b, bytes calldata p)
        public
        pure
        returns (uint256)
    {
        return a + b + p.length;
    }

    event Deposit(in uint256 amount);

    error BadInput(in(p) uint256 amount, bytes p);
}
