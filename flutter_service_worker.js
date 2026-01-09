'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "158d415ba9096d94ce3edeb2e8d103f4",
"version.json": "d7cc69e7a01d1409d00a8088a05d9cc2",
"index.html": "de2a9a07c74ff4d8cb24e3a90eafc5b5",
"/": "de2a9a07c74ff4d8cb24e3a90eafc5b5",
"CNAME": "a393bcef241c94b4d5d52b35d9c6702f",
"firebase-messaging-sw.js": "dfbe56e0966398699a1b2519994be6b8",
"main.dart.js": "e2b1878b794d323f992dab0d3a91872e",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"favicon.png": "4df16e12157e39cd54d7dbe9519743f4",
"icons/Icon-192.png": "43ac64aeb6217319e90fa9de98459af6",
"icons/Icon-maskable-192.png": "43ac64aeb6217319e90fa9de98459af6",
"icons/Icon-maskable-512.png": "250275afe18106e104f369686dd6b3dc",
"icons/Icon-512.png": "250275afe18106e104f369686dd6b3dc",
"manifest.json": "b8f713ee531d78d98107fa9b32b00c7a",
".git/ORIG_HEAD": "0f372b86b3eaad06077010adad065eec",
".git/config": "44edeb9ba179b00bee15a0ab278cf298",
".git/objects/0d/03355da99c59fb15896aec42f2bf69b15159bc": "31e2fc4db8b6b96db4736ebe2588106c",
".git/objects/0c/808f5cb7ba10637080a49fbd2b3fce8e653f87": "d0df2a5dd840826e4fab37eb5b3904e7",
".git/objects/57/7946daf6467a3f0a883583abfb8f1e57c86b54": "846aff8094feabe0db132052fd10f62a",
".git/objects/3b/6a0b2382e4edd3f5c9401b55d584cfa27de0e7": "63a555c534f8d301f525c401a995357c",
".git/objects/03/9e8f8252f9b4dbbc270cea8dff74cc7d16abc4": "713ba8950d290d440e30c753cf54a366",
".git/objects/03/2fe904174b32b7135766696dd37e9a95c1b4fd": "80ba3eb567ab1b2327a13096a62dd17e",
".git/objects/9e/1ac7462f5c6de00c6172f20973ae147b8ce8ac": "517aa080fba4441b463357494da6d9c6",
".git/objects/9e/6694e3132ab3f432ef710f29596abc211d7351": "23c1b690fd1715087f9abc1f72f85ba4",
".git/objects/35/c996a4fb4631621a732afd3e8a8b58a1bf34b9": "7bf9bda9d4766bd20221cb2c3684f0a0",
".git/objects/35/96d08a5b8c249a9ff1eb36682aee2a23e61bac": "e931dda039902c600d4ba7d954ff090f",
".git/objects/0b/78cf0a381c52db9ee2ad268af11525446df987": "13eba25f717eeab616f26c05184a586e",
".git/objects/34/03efe4c38bd35d4d410467621094fb4495ddc5": "952f4d1d4d12b10ebbf5f17ed217dd7f",
".git/objects/5f/bf1f5ee49ba64ffa8e24e19c0231e22add1631": "f19d414bb2afb15ab9eb762fd11311d6",
".git/objects/d9/3952e90f26e65356f31c60fc394efb26313167": "1401847c6f090e48e83740a00be1c303",
".git/objects/d9/255d0c02d0d7978743686d1b7b0b18922c6a42": "85d08ceac4b6c14d832f0d69e0d0b076",
".git/objects/be/3e7754fd4b5af569e9e3da72d8873bec4e47c0": "ba2c416fef3279a1d5e9dae17e7c0dc7",
".git/objects/be/06db53381b79a00d2290f8986cdf38631057dd": "dba20a00fb68509f99f956ed0f37e948",
".git/objects/a5/de584f4d25ef8aace1c5a0c190c3b31639895b": "9fbbb0db1824af504c56e5d959e1cdff",
".git/objects/bd/6be43d015a2a8a92db341ee519feb383a20cb4": "0df4c80430aff6e9b0cdd970bc215545",
".git/objects/bc/b9c5c963d0956d0aec2639c31fadf58a697f5f": "f50097314297dcdb9ce40c2ebdfda817",
".git/objects/f3/709a83aedf1f03d6e04459831b12355a9b9ef1": "538d2edfa707ca92ed0b867d6c3903d1",
".git/objects/eb/32a5881c20b607f72e17e48c60aa8694245e89": "6af275b2da3984a6ea0355279626675e",
".git/objects/c7/d591714282a1ecba62e33f1dd931cbe9cb8209": "9196142c74cbb76be375647802a3672e",
".git/objects/c7/b0bcffe25f92c1ea8c50bd8ecdedca907d26cd": "a52624948c2f15ee7beaec655727fdc3",
".git/objects/ee/7d4e4d5db351f48ad7e6339bc60330a6aa6a39": "a5711acf2205c76a2a6bb872116facba",
".git/objects/fc/ae9432c4a50b8f21b61f6baa9fc0ca8c6de902": "115b233beb9e70cce6888e7c3cc90cc7",
".git/objects/fc/3df250aa38d9fb426f782d91612dbd5b8b3484": "8ca102aa0859ed1e8a7f82963c8b6bf7",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f2/07489a76b78032bb44e054a64c2c6c426e2baa": "d04a58375d7dc6387bdbe1df12e9a54e",
".git/objects/f5/453c6425b2e6be1c02429bc00811da06490ecd": "0677fbe4fc4d5078332aa91248552613",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/e4/f727de1411053ddfdf4ef11b329ee3165e8185": "d4f8813770b51395232f7a7e9377a9dd",
".git/objects/e4/3ecc6388fdce308b5107b4488bf0beb8b15881": "ad4cd9a27baf1123c2ccb9c5430a1b3f",
".git/objects/fb/3d5c52c6180cc139ff6b7db0375d1ea9b9a844": "4249bee7de54948c9c5267ffed958f9b",
".git/objects/4e/b0fd6264c10f8a527f553c4842e33ee785c4ad": "ab9b28471a63524607308f1d7ac4f46e",
".git/objects/20/c12945ee8f5df58a01377d237fae5765cc8a65": "94c36fac63af3e1d1e38e744b5c28316",
".git/objects/18/496acba7e3d8480b8cfa239f6098f24b3f7406": "16cb9c25dc896267a53ca86ded163306",
".git/objects/18/dec77c0261d4b6ed4ac4011a5bc6e3530cedcf": "1eda2978315fbe61e378e07aa450815e",
".git/objects/4b/02e9b25e25d77e3db67c4763909c0c090559db": "b7f4a5bd4aad945be72818a53c1af740",
".git/objects/pack/pack-1212ac94f3bfa602b915601a9e62b16420abcbe5.pack": "5579ae316fb13706c6e1ff65bb7666e3",
".git/objects/pack/pack-1212ac94f3bfa602b915601a9e62b16420abcbe5.idx": "f292671d54b10416a52b6359ed7bdf30",
".git/objects/7c/0ff2eaa0b08b43a293ffc43e07357f64d8c871": "e3b821187bec3a425dbc576559c62dd9",
".git/objects/89/f8fe40c95073e87422662fb0b92737da9fa1f4": "d76177a23c7f6d825723d74ec03f3c96",
".git/objects/89/d82158b52744829fc5eb55d832b9322d7b6404": "b571409221bab2f84e36bea42b803a43",
".git/objects/80/b8cdf6260cbb4f59ba0ea6c448688d29fb126f": "199e50e7bf4c6bb744124c3e86e75916",
".git/objects/1a/d439d876d69abb05031fc6efba3addaf99b05c": "a62998af7d1230832059b08e041be062",
".git/objects/8a/51a9b155d31c44b148d7e287fc2872e0cafd42": "9f785032380d7569e69b3d17172f64e8",
".git/objects/4c/6e7e8121999e2b2b5e66a5b8fb98207c5e051e": "7edccb133053da38af263e0f556fb1ad",
".git/objects/21/b6faf1977ab15f390d6e36c704ea42344c87c8": "29e8f3f7ddf16de8d8f750e5cbc44641",
".git/objects/81/35241c005af1245c241e9418f47cfff499aaec": "c8345bde31ea2e9ce8e9cb419a05e327",
".git/objects/86/006d6ba417ca5b1c3d61ddf54921eba92e4b6a": "41783eb2fa885a28f35609ea38c39ab5",
".git/objects/72/a73b075cbeb3c1042de5026320bf2ba757284b": "68aecd3d0c3e25bc4561e45f6201f24e",
".git/objects/2a/90f2162fcb1b7e3849ea306a87cbbf0228b236": "b7025e08b3fd87bd4b715e62ebd4f8b7",
".git/objects/43/c853c0967f00e14447cbf5d975f13fbcf50fb5": "0cdf90731d11a83edb3412cda0a215be",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/07/69493759cf4ed47ca5d21ed249ac8ea34cd9b3": "ea18d471bbb923bf7af5d8ed6c2de07c",
".git/objects/38/734c6bd72cdf82594854029bda935aba463d7e": "dff989928e4c9d3e58954b9785da8a95",
".git/objects/38/4290f596ed1215fc5fd861b851900f5d1fe7bc": "689ec76e60d5f217ae2e7abbb9385a09",
".git/objects/00/ed39c2d460951e4ca72ac651946991b513cd31": "f47de3d06162c168775ec3cab35090a1",
".git/objects/00/a4d638dd776f657d13cf30642ee6e148071ec8": "c97a5ca8598b32b709ceac2d9e8862f2",
".git/objects/36/7ea7451f240d337ea79202a60a4c267eac7cf8": "541df70540182ad6ba6bbb588684f374",
".git/objects/91/4a40ccb508c126fa995820d01ea15c69bb95f7": "8963a99a625c47f6cd41ba314ebd2488",
".git/objects/65/6fc8bf0a26ea4a2223622e943486515097f4e1": "def50401f89a2fcc021fde0483e77457",
".git/objects/65/bafeea49b29e46a1feea8033cc06d5f045bd45": "f865647a4aa36fc3a5ce8052d9139a5a",
".git/objects/96/25c239ee8c2e361d4d71ef371e5d3069d6e301": "0814e146117d914d4be245a00ff945df",
".git/objects/3a/c4b8e7bb8f3a74255f73428247bc527b9dd3cf": "b8aaef20e352a72dcae8b89c74ba3446",
".git/objects/54/d464373fdcacbdbb5666afa3c118858dcdf871": "86a312407caf952197dbd6d4de9cebcc",
".git/objects/30/41a081f955445e6ef3db50a7b0834cccc0078a": "75488d9dca4b00367309c5362773a7ea",
".git/objects/37/3eb67339b94ff7d976f97f35d5168a52fcfd56": "f3b6532bc68592a4230b6a4631657da7",
".git/objects/08/231e87ced41e6f7ad9d981200f6194b8aaa57f": "bc5e603974b92843d586ade23d492a4c",
".git/objects/01/00c5401903fecb9cfd1df253f81e8ed8d2a292": "a1256e15fe247e8056ac5becc717fda6",
".git/objects/6c/947be00f815a57152bd24c43eb838661da2731": "a82090f5e309da42b7e4af5d43264ff2",
".git/objects/97/a0a3f6b9cf9ea963e24386e13e6b28aae547f7": "90dc911b6e0b9ae93d2c1e301d01dc35",
".git/objects/0f/cc7b285a8bac8b35c4613e234e5c8acfebbec8": "c7b9e893468877e38f869831e076adb4",
".git/objects/0a/2968ae40907c3cb10d2c16953c4cd672c6ad2e": "e097033c1ef95af269c2efe6f00f6e25",
".git/objects/90/a7b54c7013ef6047efb856ab9ca3b0e48db970": "9ee9ba6caf6af8b7d197ca564fa459e0",
".git/objects/90/0f0090a7eb93ec6e23a5a36b274f128df7b704": "c19e9d2b33a0ae3d7c62f4bca040463d",
".git/objects/90/952fc8c23a4f86e9eea1f81e3be41607d12efc": "c3dafdeb02052aed56273c322debc4bf",
".git/objects/d3/490732d7138fa6572990594d45206154978d9e": "9329ce6f089578dba2c75bce54924478",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/ba/84ba411ee1cce6593a507ab27b6df91d89f1c5": "790ba86585a499925be759e880d50d63",
".git/objects/ba/b469934863fb84fefa3e9c77a0253a0cf31d76": "57cad561342b7bea91f59d33d6c4613b",
".git/objects/ba/a6d9d0305bf4d92c0f1aa3c53ee1723a1f1643": "05e3a70a76373734ab5a4854cb4dfb0c",
".git/objects/a7/6d68c885b9e69b86d8cf6b4f9370734a3d4c09": "0b71e5d5aac5520cadb24b71374daed8",
".git/objects/a7/18555855926900abf65e4d8817e4ca7433e554": "bb5c23647ba17e7336372e398220d7f5",
".git/objects/a7/b21513390957275920747781190a177d16298d": "96af7352aad243b43d921611626ec184",
".git/objects/b1/ca52ad0ef867daec457c4c7a812744237c7dfc": "f05b9d65539f34b0969451c6f110e85e",
".git/objects/dd/90e0e43f3212e45d37fa0dabc961c5594b5b82": "dd6e5fb9fce0f4b65237f6f7eeca60eb",
".git/objects/dc/f83695f71da8c6278eb914cdd42692c427924e": "9ca7f32e12839dea4610032ada023058",
".git/objects/b7/7436fda0de1889517bae3eb45451bda278b501": "864940195e756e053a4a7fc88db2a139",
".git/objects/b7/1524f68ab4bb7dfd34fd9d25630b4b26b56e83": "8023b208bd19bb35378050264125685a",
".git/objects/db/b3cc60226b8c1009f34dd6d0533e1e23f98651": "15af9524d664e39a6f548412b724c2e3",
".git/objects/a8/8c9340e408fca6e68e2d6cd8363dccc2bd8642": "11e9d76ebfeb0c92c8dff256819c0796",
".git/objects/de/9c160bd7c138229c6a4ca34aa61d629e5b9546": "434bc9ed021baaf2672ec83d61e4605c",
".git/objects/ef/b875788e4094f6091d9caa43e35c77640aaf21": "27e32738aea45acd66b98d36fc9fc9e0",
".git/objects/c4/3497bf387138e95dad2f048e2f1d76060697a5": "380ca463274ef0fe7cf4b3a801985e5a",
".git/objects/cd/29d4f9a770b7f641ec6e158551e3c599d3ae5b": "35cb99de104969cd4428f831a7eebfb7",
".git/objects/cd/c11e23c9468cab367817cb82a789696c56c528": "f41c3c43397b95a1db3781dda45918dc",
".git/objects/e6/2c8b769a2e0bd89d490a44dd10fe8eb7388db0": "59d7416cb125bbea9ef11cc79783fefb",
".git/objects/f9/d7c63ed8823e7cf367186d79b82be4ecfab4ad": "9b4e9214f6b0559e9040bb9b989f0c2e",
".git/objects/c2/fd115f9b1105342a96c6a476c38f1fe7a0d186": "d7a82994ddd9dc9da4ebe59e1af52f37",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/e7/77e45264e5019094793be17d2ee0c897bca90b": "3950372cc72401a08195f0316d25c089",
".git/objects/f8/6bf8f83c45a598383a21b6d7d20f74eb1c544d": "83c2bf31718832bc6e5c76dd53d51e32",
".git/objects/e0/89fbaaff3cc9d8441ac8af3b884424406e18f5": "da79f9ccb4fdec0afac97242de1227f7",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/46/3f1f4bd1b58b39eaee8f9d29caa196c10709d0": "6362083f8f0427dd5108073343496064",
".git/objects/41/d253bd58113105b3602b74ef77309c09ad7048": "1593142422e40cc206a699a1223ca319",
".git/objects/4f/02e9875cb698379e68a23ba5d25625e0e2e4bc": "254bc336602c9480c293f5f1c64bb4c7",
".git/objects/12/76f58ae0fe00ce06ca405983a1e08b1c13147c": "426171e41f6054e3ea08d6de6ea32a83",
".git/objects/12/8a16d8ca651a654d1ee2a91d04b2c25af34d11": "e58c793b8aa7540f7d21226fa31d798d",
".git/objects/8c/7736f748b4087b4337d55efc1c000c94614349": "e8b99f48163ca2e2198c79ecd9165070",
".git/objects/8c/99e6dc647bc13f0f47133b81296b0a59a07639": "270ad21118a5b1315d76108646e33fc9",
".git/objects/71/ef803dc655f6adae80421c8b7477f27d26245d": "9beb52fe38d6e2d837aae7119304f323",
".git/objects/76/c3041fd755b88a82435d1192b1c71738f4a86c": "20b69ab445bd888547d51ed9e55ad6eb",
".git/objects/1c/51230bbc90cd975179992e7d33286905dcc6a8": "c696fbbf6123f08b472d5f286cd12d2f",
".git/objects/82/477eff1366b19683b8af94fef37462b7c2943f": "1f71993c5adf98475d1aac5155f95ff7",
".git/objects/40/1184f2840fcfb39ffde5f2f82fe5957c37d6fa": "1ea653b99fd29cd15fcc068857a1dbb2",
".git/objects/78/bec328d2efe28d429669da5093f51f7b8eafb7": "0649c36032ab34e5f95c84b51858e950",
".git/objects/7f/4d09c102a9d4db658604924d569f79075bae0c": "b248b4194e4519c43c9df397af14f0b4",
".git/objects/7f/b2585a82d38e31645a11f20a5c8b48692ba380": "1804397a529cec0c657f7d3d89f2ee3b",
".git/objects/7a/4f354b84aa571740a1920dc4e3ff3b4fca0620": "234000968ae0ffef52b0c73f438cdc36",
".git/objects/8e/8f9657cc8a4d72a77ed2e98334128061228346": "f527577983f34e41c84c6e6d60a49380",
".git/objects/25/be09c35e97d3708e3ee2a2e0f60d4124118715": "daaf798b19c99176f58c43236b66a4c6",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "07039e16af2831769ba933d15af33042",
".git/logs/refs/heads/main": "e713c37e15065a976c36a609bf4d2275",
".git/logs/refs/remotes/origin/development": "f6e6da30e05441213e772d0b3f3f23f8",
".git/logs/refs/remotes/origin/main": "1a0413f6eab65fb4ba23c2e0bf1c2d21",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-commit.sample": "305eadbbcd6f6d2567e033ad12aabbc4",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/main": "93e24361665f2fe09af0974cfbf42617",
".git/refs/remotes/origin/development": "75473f432a32df5abe9177f297c39ab7",
".git/refs/remotes/origin/main": "93e24361665f2fe09af0974cfbf42617",
".git/index": "f87047b67e16dc6d3e1c8c0798c94f7d",
".git/COMMIT_EDITMSG": "a2fefb6aae601ec6360b2dfbacfd766d",
".git/FETCH_HEAD": "9bf5cd4c40ebc40849f096ef8022311d",
"assets/AssetManifest.json": "2956214439abcd25f6776239730f304e",
"assets/NOTICES": "e45cf92db6177cf45fcf1d1bfc8c7489",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "0fcda92c92e1047986f0f60cd6dd5f89",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/record_web/assets/js/record.fixwebmduration.js": "1f0108ea80c8951ba702ced40cf8cdce",
"assets/packages/record_web/assets/js/record.worklet.js": "356bcfeddb8a625e3e2ba43ddf1cc13e",
"assets/packages/hmssdk_flutter/lib/assets/sdk-versions.json": "91b5900699f93c86b1bb5df6711faa31",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "b733bc771efb97a6fec0d1c0c77b82e9",
"assets/fonts/MaterialIcons-Regular.otf": "d6160b96d64b0af5a150ea38caa6d357",
"assets/assets/icons/likes.svg": "2cc9756d49b2cb1b598c896b2a4d1b03",
"assets/assets/icons/nookly_logo_updated.png": "248ebd5611cf89397d426b18979eac1a",
"assets/assets/icons/app_icon.png": "4c79942db1f079bb848cbcfc0cec95dc",
"assets/assets/icons/discover.svg": "66746996d0fce2416339836285569305",
"assets/assets/icons/google_icon.svg": "54e0cfbd9e5276338d0006f737428f86",
"assets/assets/icons/chats.svg": "fa22f72f22f5aa9c56f2ae2e867f3f6d",
"assets/assets/icons/nookly_secondary_icon.png": "57ba993e2341e7859cac29d9ac435726",
"assets/assets/icons/premium.svg": "c82836e73a07d0dd17a5bf464f1845cc",
"assets/assets/icons/nookly_dark_icon.png": "68e2e6c3e315e6ac750eb8bd82641068",
"assets/assets/icons/chats_old.svg": "a6ec0b0c17b6c022ab71ef6fc62c3684",
"assets/assets/icons/profile.svg": "88ea52376fa87785743b1cfe1e643d8f",
"assets/assets/icons/discover_old.svg": "031323a97dbc216f5fcfc8c612881360",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
