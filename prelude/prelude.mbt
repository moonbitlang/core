pub typealias ArgsLoc = @builtin.ArgsLoc
pub typealias Array[X] = @builtin.Array[X]
pub typealias ArrayView[X] = @builtin.ArrayView[X]
pub typealias UninitializedArray[X] = @builtin.UninitializedArray[X]
pub typealias BigInt = @builtin.BigInt
pub typealias Failure = @builtin.Failure
pub typealias Hasher = @builtin.Hasher
pub typealias Iter[X] = @builtin.Iter[X]
pub typealias Iter2[X, Y] = @builtin.Iter2[X, Y]
pub typealias IterResult = @builtin.IterResult
pub typealias Json = @builtin.Json
pub typealias Map[K, V] = @builtin.Map[K, V]
pub typealias Set[X] = @builtin.Set[X]
pub typealias InspectError = @builtin.InspectError
pub typealias SnapshotError = @builtin.SnapshotError
pub typealias SourceLoc = @builtin.SourceLoc
pub typealias StringBuilder = @builtin.StringBuilder
pub typealias Eq = @builtin.Eq
pub typealias Compare = @builtin.Compare
pub typealias Hash = @builtin.Hash
pub typealias Logger = @builtin.Logger
pub typealias Show = @builtin.Show
pub typealias ToJson = @builtin.ToJson
pub typealias Default = @builtin.Default

pub fn abort[T](msg : String) -> T { @builtin.abort(msg) }

pub fn assert_eq[T : Eq + Show](x : T, y : T, loc~ : SourceLoc = _) -> Unit! {
  @builtin.assert_eq!(x, y, loc~)
}

pub fn assert_not_eq[T : Eq + Show](x : T, y : T, loc~ : SourceLoc = _) -> Unit! {
  @builtin.assert_not_eq!(x, y, loc~)
}

pub fn assert_true(cond : Bool, loc~ : SourceLoc = _) -> Unit! {
  @builtin.assert_true!(cond, loc~)
}

pub fn assert_false(cond : Bool, loc~ : SourceLoc = _) -> Unit! {
  @builtin.assert_false!(cond, loc~)
}

pub fn fail[T](msg : String, loc~ : SourceLoc = _) -> T!Failure {
  @builtin.fail!(msg, loc~)
}

pub fn ignore[T](_x : T) -> Unit {}

pub fn inspect(obj : Show, content~ : String = "", loc~ : SourceLoc = _, args_loc~ : ArgsLoc = _) -> Unit!InspectError {
  @builtin.inspect!(obj, content~, loc~, args_loc~)
}

pub fn panic[T]() -> T {
  @builtin.panic()
}

pub fn physical_equal[T](x : T, y : T) -> Bool {
  @builtin.physical_equal(x, y)
}

/// @alert deprecated "Use `println` instead"
pub fn print[T : Show](x : T) -> Unit {
  @builtin.print(x)
}

pub fn println[T : Show](x : T) -> Unit {
  @builtin.println(x)
}

pub fn not(x : Bool) -> Bool = "%bool_not"
