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
test "is_probable_prime" {
  let r = @random.Rand::new()
  // small primes
  inspect(is_probable_prime(2N, r), content="true")
  inspect(is_probable_prime(3N, r), content="true")
  inspect(is_probable_prime(7N, r), content="true")
  inspect(is_probable_prime(17N, r), content="true")
  // https://t5k.org/lists/small
  inspect(is_probable_prime(5915587277N, r), content="true")
  inspect(is_probable_prime(1500450271N, r), content="true")
  inspect(is_probable_prime(48112959837082048697N, r), content="true")
  inspect(is_probable_prime(27542476619900900873N, r), content="true")
  inspect(
    is_probable_prime(
      643808006803554439230129854961492699151386107534013432918073439524138264842370630061369715394739134090922937332590384720397133335969549256322620979036686633213903952966175107096769180017646161851573147596390153N,
      r,
    ),
    content="true",
  )
  inspect(
    is_probable_prime(
      449417999055441493994709297093108513015373787049558499205492347871729927573118262811508386655998299074566974373711472560655026288668094291699357843464363003144674940345912431129144354948751003607115263071543163N,
      r,
    ),
    content="true",
  )
  inspect(
    is_probable_prime(
      5521712099665906221540423207019333379125265462121169655563495403888449493493629943498064604536961775110765377745550377067893607246020694972959780839151452457728855382113555867743022746090187341871655890805971735385789993N,
      r,
    ),
    content="true",
  )

  // small composites
  inspect(is_probable_prime(0N, r), content="false")
  inspect(is_probable_prime(1N, r), content="false")
  inspect(is_probable_prime(93N, r), content="false")
  inspect(is_probable_prime(133N, r), content="false")
  // big composites
  inspect(
    is_probable_prime(
      21284175091214687912771199898307297748211672914763848041968395774954376176754N,
      r,
    ),
    content="false",
  )
  inspect(
    is_probable_prime(
      6084766654921918907427900243509372380954290099172559290432744450051395395951N,
      r,
    ),
    content="false",
  )
  inspect(
    is_probable_prime(
      84594350493221918389213352992032324280367711247940675652888030554255915464401N,
      r,
    ),
    content="false",
  )
  // carmichael numbers
  inspect(is_probable_prime(561N, r), content="false")
  inspect(is_probable_prime(1729N, r), content="false")
  inspect(is_probable_prime(41041N, r), content="false")
  inspect(is_probable_prime(509033161N, r), content="false")
}

///|
test "probable_prime" {
  let rand = @random.Rand::new()
  inspect(is_probable_prime(probable_prime(32, rand), rand), content="true")
  inspect(is_probable_prime(probable_prime(64, rand), rand), content="true")
  inspect(is_probable_prime(probable_prime(100, rand), rand), content="true")
  inspect(is_probable_prime(probable_prime(256, rand), rand), content="true")
}
