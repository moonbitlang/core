// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
test "BigInt::probably_prime" {
  let r = @random.new()
  // small primes
  inspect!(2N.probably_prime(r), content="true")
  inspect!(3N.probably_prime(r), content="true")
  inspect!(7N.probably_prime(r), content="true")
  inspect!(17N.probably_prime(r), content="true")
  // https://t5k.org/lists/small
  inspect!(5915587277N.probably_prime(r), content="true")
  inspect!(1500450271N.probably_prime(r), content="true")
  inspect!(48112959837082048697N.probably_prime(r), content="true")
  inspect!(27542476619900900873N.probably_prime(r), content="true")
  inspect!(
    643808006803554439230129854961492699151386107534013432918073439524138264842370630061369715394739134090922937332590384720397133335969549256322620979036686633213903952966175107096769180017646161851573147596390153N.probably_prime(
      r,
    ),
    content="true",
  )
  inspect!(
    449417999055441493994709297093108513015373787049558499205492347871729927573118262811508386655998299074566974373711472560655026288668094291699357843464363003144674940345912431129144354948751003607115263071543163N.probably_prime(
      r,
    ),
    content="true",
  )
  inspect!(
    5521712099665906221540423207019333379125265462121169655563495403888449493493629943498064604536961775110765377745550377067893607246020694972959780839151452457728855382113555867743022746090187341871655890805971735385789993N.probably_prime(
      r,
    ),
    content="true",
  )

  // small composites
  inspect!(0N.probably_prime(r), content="false")
  inspect!(1N.probably_prime(r), content="false")
  inspect!(93N.probably_prime(r), content="false")
  inspect!(133N.probably_prime(r), content="false")
  // big composites
  inspect!(
    21284175091214687912771199898307297748211672914763848041968395774954376176754N.probably_prime(
      r,
    ),
    content="false",
  )
  inspect!(
    6084766654921918907427900243509372380954290099172559290432744450051395395951N.probably_prime(
      r,
    ),
    content="false",
  )
  inspect!(
    84594350493221918389213352992032324280367711247940675652888030554255915464401N.probably_prime(
      r,
    ),
    content="false",
  )
  // carmichael numbers
  inspect!(561N.probably_prime(r), content="false")
  inspect!(1729N.probably_prime(r), content="false")
  inspect!(41041N.probably_prime(r), content="false")
  inspect!(509033161N.probably_prime(r), content="false")
}
