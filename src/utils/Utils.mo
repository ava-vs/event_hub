import Blob "mo:base/Blob";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";

import E "../EventTypes";
module {
    public func getValueFromMetadata(key : Text, metadata : ?[(Text, E.Metadata)]) : ?E.Metadata {
        switch (metadata) {
            case (null) { null };
            case (?entries) {
                for ((k, value) in entries.vals()) {
                    if (k == key) {
                        return ?value;
                    };
                };
                null;
            };
        };
    };

    public func getNat8ValueFromMetadata(value : ?E.Metadata) : Nat8 {
        switch (value) {
            case (null) { 0 };
            case (?v) {
                switch (v) {
                    case (#Nat8(n)) {
                        return n;
                    };
                    case (#Nat(n)) {
                        return Nat8.fromNat(n);
                    };
                    case (#Blob(b)) { Blob.toArray(b)[0] };
                    case (#Bool(_)) { 0 };
                    case (#Int(n)) { Nat8.fromIntWrap(n) };
                    case (#Text(t)) {
                        Nat8.fromNat(Option.get<Nat>(Nat.fromText(t), 0));
                    };
                };

            };
        };
    };

    public func getTextValueFromMetadata(value : ?E.Metadata) : Text {
        switch (value) {
            case (null) { "" };
            case (?v) {
                switch (v) {
                    case (#Nat(_)) { "" };
                    case (#Nat8(_)) { "" };
                    case (#Blob(_)) { "" };
                    case (#Bool(_)) { "" };
                    case (#Int(_)) { "" };
                    case (#Text(t)) { t };
                };

            };
        };
    };

    // convert date prefix from Int to date

	public func timestampToDate() : Text {
		let start2024 = Time.now() - 1_704_067_200_000_000_000;
		let seconds = start2024 / 1_000_000_000;
		let minutes = Int.div(seconds, 60);
		let hours = Int.div(minutes, 60);
		let days = Int.div(hours, 24);

		let secondsInMinute = seconds % 60;
		let minutesInHour = minutes % 60;
		let hoursInDay = hours % 24;

		let years = Int.div(days, 365);
		let year = years + 2024;
		var remainingDays = days - (years * 365);

		let monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
		var month = 1;
		label l for (i in monthDays.vals()) {
			if (remainingDays < i) break l;
			remainingDays -= i;
			month += 1;
		};

		let day = remainingDays + 1;

		return Int.toText(year) # "-" # Int.toText(month) # "-"
		# Int.toText(day) # " " # Int.toText(hoursInDay) # ":"
		# Int.toText(minutesInHour) # ":" # Int.toText(secondsInMinute);
	};
    
   	public func pushIntoArray<X>(elem : X, array : [X]) : [X] {
		let buffer = Buffer.fromArray<X>(array);
		buffer.add(elem);
		return Buffer.toArray(buffer);
	};

	public func appendArray<X>(array1 : [X], array2 : [X]) : [X] {
		let buffer1 = Buffer.fromArray<X>(array1);
		let buffer2 = Buffer.fromArray<X>(array2);
		buffer1.append(buffer2);
		Buffer.toArray(buffer1);
	};

    // For <SFFNNNGGG> cifer
    public func convertCiferToDottedFormat(cifer : Text) : Text {
        let chars = Text.toArray(cifer);
        let s = Text.fromChar(chars[0]);
        let ff = Text.fromChar(chars[1]) # Text.fromChar(chars[2]);
        let nnn = Text.fromChar(chars[3]) # Text.fromChar(chars[4]) # Text.fromChar(chars[5]);
        let ggg = Text.fromChar(chars[6]) # Text.fromChar(chars[7]) # Text.fromChar(chars[8]);
        return Text.join(".", [s, ff, nnn, ggg].vals());
    };

};
