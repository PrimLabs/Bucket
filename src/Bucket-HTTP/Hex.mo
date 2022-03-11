import Array "mo:base/Array";
import Char "mo:base/Char";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Result "mo:base/Result";

module {
    private let base : Nat8   = 16;
    private let hex  : [Char] = [
        '0', '1', '2', '3', 
        '4', '5', '6', '7', 
        '8', '9', 'A', 'B', 
        'C', 'D', 'E', 'F',
    ];

    // Converts a byte to its corresponding hexidecimal format.
    public func encodeByte(n : Nat8) : Text {
        let c0 = hex[Nat8.toNat(n / base)];
        let c1 = hex[Nat8.toNat(n % base)];
        Char.toText(c0) # Char.toText(c1);
    };

    // Converts an array of bytes to their corresponding hexidecimal format.
    public func encode(ns : [Nat8]) : Text {
        Array.foldRight<Nat8, Text>(
            ns, 
            "", 
            func(n : Nat8, acc : Text) : Text {
                encodeByte(n) # acc;
            },
        );
    };

    // Converts the given hexadecimal character to its corresponding binary format.
    // NOTE: a hexadecimal char is just an 4-bit natural number.
    public func decodeChar(c : Char) : Result.Result<Nat8,Text> {
        for (i in hex.keys()) {
            if (hex[i] == c) {
                return #ok(Nat8.fromNat(i));
            }
        };
        #err("Unexpected character: " # Char.toText(c));
    };

    // Converts the given hexidecimal text to its corresponding binary format.
    public func decode(t : Text) : Result.Result<[Nat8],Text> {
        var cs = Iter.toArray(t.chars());
        if (cs.size() % 2 != 0) {
            cs := Array.append(['0'], cs);
        };
        let ns = Array.init<Nat8>(cs.size() / 2, 0);
        for (i in Iter.range(0, ns.size() - 1)) {
            let j : Nat = i * 2;
            switch (decodeChar(cs[j])) {
                case (#err(e)) { return #err(e); };
                case (#ok(x0)) {
                    switch (decodeChar(cs[j+1])) {
                        case (#err(e)) { return #err(e); };
                        case (#ok(x1)) {
                            ns[i] := x0 * base + x1;
                        };
                    };
                };
            };
        };
        #ok(Array.freeze(ns));
    };
};
