## 2. Công nghệ và Công cụ sử dụng

Để xây dựng hệ thống ứng dụng tích hợp trí tuệ nhân tạo hỗ trợ người khiếm thị, đồ án sử dụng kết hợp nhiều công nghệ ở cả phía máy chủ và phía thiết bị di động. Kiến trúc công nghệ được tổ chức theo hướng phân tách trách nhiệm giữa Mobile và Server. Trong đó, thiết bị di động đảm nhiệm vai trò tương tác trực tiếp với người dùng, thu nhận dữ liệu từ camera và microphone, gửi dữ liệu tới máy chủ và cung cấp kết quả phản hồi. Máy chủ chịu trách nhiệm tiếp nhận dữ liệu, xử lý các yêu cầu từ ứng dụng, duy trì phiên làm việc, điều phối các mô-đun trí tuệ nhân tạo và gửi kết quả hoặc cảnh báo trở lại thiết bị. 

Đặc điểm của hệ thống là quá trình nhận diện và phân tích trí tuệ nhân tạo được thực hiện phía Server. Thiết bị di động không thực hiện các mô hình AI ngoại tuyến. Vì vậy, việc giao tiếp mạng giữa Mobile và Server là thành phần quan trọng của kiến trúc. Khi thiết bị có kết nối, dữ liệu hình ảnh hoặc âm thanh có thể được gửi tới máy chủ để xử lý. Khi mất kết nối, các chức năng phụ thuộc vào máy chủ như nhận diện và quét an toàn sẽ tạm dừng cho đến khi kết nối được khôi phục. 

Bên cạnh các công nghệ lập trình chính, đồ án sử dụng các giao thức truyền thông, cơ chế xác thực phiên, phương thức bảo vệ đường truyền, cơ chế lưu trữ cấu hình và các công cụ hỗ trợ phát triển, kiểm thử và quản lý mã nguồn. Việc lựa chọn công nghệ được thực hiện dựa trên yêu cầu thực tế của hệ thống, trong đó tập trung vào khả năng xử lý dữ liệu hình ảnh và âm thanh, giao tiếp giữa thiết bị với máy chủ, phản hồi theo thời gian thực, khả năng tiếp cận đối với người khiếm thị và tính đơn giản phù hợp với phạm vi của đồ án. 

## 2.1. Phía Server

## 2.1.1. Ngôn ngữ lập trình Python

## a) Giới thiệu

Python là một ngôn ngữ lập trình bậc cao, có cú pháp tương đối rõ ràng, dễ đọc và hỗ trợ nhiều mô hình lập trình khác nhau. Python được Guido van Rossum phát triển và phiên bản đầu tiên được công bố vào năm 1991. Hiện nay, Python được sử dụng rộng rãi trong nhiều lĩnh vực như phát triển phần mềm, xử lý dữ liệu, khoa học dữ liệu, trí tuệ nhân tạo và học máy. 

Trong quá trình thực thi, mã nguồn Python trong môi trường CPython thường được chuyển đổi thành dạng bytecode và được thực thi bởi môi trường thực thi của Python. Cách tiếp cận này cung cấp mức độ trừu tượng tương đối cao, giúp lập trình viên tập trung vào việc xây dựng logic ứng dụng thay vì phải quản lý trực tiếp nhiều chi tiết cấp thấp của hệ thống. 

Trong đồ án, Python được lựa chọn làm ngôn ngữ lập trình chính cho phía Server. Python được sử dụng để xây dựng các thành phần xử lý phía máy chủ, triển khai API, xử lý dữ liệu nhận từ thiết bị di động và tích hợp với các mô-đun trí tuệ nhân tạo. Server đóng vai trò trung gian giữa ứng dụng di động và các thành phần xử lý AI, do đó Python cần đáp ứng đồng thời yêu cầu về phát triển API, xử lý dữ liệu và tích hợp thư viện AI. Đồ án sử dụng Python phiên bản 3.12. 

## b) Đặc điểm

Một trong những đặc điểm của Python là cơ chế định kiểu động. Kiểu dữ liệu của đối tượng được xác định trong quá trình thực thi thay vì yêu cầu khai báo kiểu cứng cho mọi biến ngay từ đầu. Đặc điểm này giúp mã nguồn tương đối linh hoạt và thuận tiện khi xử lý nhiều loại dữ liệu khác nhau. 

Trong hệ thống, server có thể phải tiếp nhận dữ liệu JSON, thông tin phiên, thông tin yêu cầu, đường dẫn tệp, dữ liệu hình ảnh hoặc âm thanh. Khả năng xử lý linh hoạt các kiểu dữ liệu giúp Python thuận tiện trong việc xây dựng các thành phần trung gian giữa API và mô-đun AI. 

Python đồng thời hỗ trợ nhiều mô hình lập trình như lập trình hướng đối tượng, lập trình thủ tục và lập trình hàm. Nhờ đó, mã nguồn phía server có thể được tổ chức thành các thành phần có trách nhiệm tương đối độc lập. Các đối tượng hoặc lớp có thể được sử dụng để tổ chức những thành phần có trạng thái, trong khi các thao tác xử lý độc lập có thể được xây dựng dưới dạng hàm. 

Một đặc điểm quan trọng khác của Python là hệ sinh thái thư viện phong phú. Trong lĩnh vực AI và xử lý dữ liệu, các thư viện như NumPy, PyTorch và OpenCV cung cấp nhiều chức năng phục vụ tính toán số, xử lý hình ảnh và triển khai mô hình học máy. Nhờ đó, nhóm phát triển có thể sử dụng các thành phần có sẵn thay vì phải tự xây dựng toàn bộ các thuật toán nền tảng. 

Đối với đồ án, hệ sinh thái Python đặc biệt phù hợp vì dữ liệu cần xử lý không chỉ là văn bản mà còn có thể bao gồm hình ảnh và âm thanh. Python cung cấp môi trường thuận tiện để kết nối các bước tiếp nhận dữ liệu, tiền xử lý, gọi mô hình AI và chuẩn hóa kết quả trước khi trả về ứng dụng. 

## c) Ưu điểm

Ưu điểm đầu tiên của Python là khả năng phát triển tương đối nhanh. Cú pháp ngắn gọn và cách tổ chức mã nguồn rõ ràng giúp nhóm thuận tiện trong quá trình xây dựng, kiểm thử và sửa đổi hệ thống. Đối với một đồ án có tính chất nghiên cứu và thử nghiệm, khả năng thay đổi nhanh các thành phần xử lý là một lợi thế đáng kể. 

Python cũng có hệ sinh thái mạnh trong lĩnh vực trí tuệ nhân tạo và xử lý dữ liệu. Các thư viện phục vụ tính toán, xử lý hình ảnh và học máy giúp nhóm có thể tập trung vào việc tích hợp các mô-đun vào kiến trúc hệ thống thay vì phải triển khai lại toàn bộ chức năng nền tảng. 

Bên cạnh đó, Python có khả năng hoạt động trên nhiều hệ điều hành và có thể tích hợp với các thành phần được xây dựng bằng những ngôn ngữ khác. Điều này tạo điều kiện thuận lợi cho quá trình phát triển và triển khai server. 

## d) Nhược điểm

Một hạn chế của Python là hiệu năng có thể thấp hơn một số ngôn ngữ biên dịch như C hoặc C++ đối với những tác vụ tính toán thuần túy. Vấn đề này cần được xem xét nếu server trực tiếp thực hiện các tác vụ có yêu cầu tính toán lớn. 

Ngoài ra, khi sử dụng CPython, Global Interpreter Lock (GIL) giới hạn việc nhiều thread thực thi đồng thời mã Python trong cùng một tiến trình. Hạn chế này đáng chú ý đối với các tác vụ CPU-bound. Trong trường hợp cần xử lý các công việc tính toán nặng, hệ thống có thể sử dụng worker, multiprocessing hoặc cơ chế xử lý phù hợp khác thay vì để toàn bộ công việc được thực hiện trực tiếp trong thread xử lý request. 

## e) Lý do lựa chọn

Python được lựa chọn vì phù hợp với đặc điểm của hệ thống, trong đó máy chủ vừa phải cung cấp API cho ứng dụng di động, vừa phải xử lý dữ liệu và tích hợp các mô-đun trí tuệ nhân tạo. Việc sử dụng Python cho các thành phần phía Server giúp nhóm thống nhất môi trường phát triển và thuận tiện kết nối giữa tầng API với các thư viện xử lý AI. 

Đặc biệt, hệ thống cần xử lý dữ liệu hình ảnh và âm thanh được gửi từ thiết bị di động. Hệ sinh thái Python cung cấp nhiều thư viện phù hợp với các bài toán này, do đó giảm thời gian phát triển các thành phần nền tảng và cho phép nhóm tập trung vào kiến trúc và chức năng của đồ án. 

## 2.1.2. Khung ứng dụng FastAPI và máy chủ Uvicorn

## a) Giới thiệu

FastAPI là một framework web mã nguồn mở dành cho Python, được thiết kế để xây dựng các API. FastAPI sử dụng Starlette cho các thành phần liên quan đến web và xử lý bất đồng bộ, đồng thời sử dụng Pydantic để mô hình hóa và kiểm tra dữ liệu. 

Trong đồ án, FastAPI đảm nhiệm tầng API phía Server. Khi ứng dụng di động gửi yêu cầu, FastAPI tiếp nhận request, thực hiện các bước kiểm tra cần thiết, xác định loại yêu cầu và chuyển dữ liệu tới thành phần xử lý tương ứng. Sau khi xử lý hoàn tất, FastAPI trả kết quả về ứng dụng hoặc sử dụng WebSocket để gửi thông tin tới client trong những trường hợp cần phản hồi theo thời gian thực. 

Uvicorn là máy chủ web hỗ trợ chuẩn ASGI và được sử dụng để chạy ứng dụng FastAPI. Có thể hiểu FastAPI chịu trách nhiệm xây dựng các endpoint và logic API, trong khi Uvicorn cung cấp môi trường để ứng dụng FastAPI tiếp nhận và xử lý các kết nối mạng. 

## b) Đặc điểm

Một đặc điểm quan trọng của FastAPI là hỗ trợ mô hình lập trình bất đồng bộ thông qua async và await. Cơ chế này phù hợp với những thao tác có thời gian chờ như giao tiếp mạng, đọc dữ liệu hoặc gọi các dịch vụ khác. Khi một tác vụ đang chờ I/O, server có thể tiếp tục xử lý các công việc phù hợp khác thay vì phải giữ tiến trình ở trạng thái chờ. 

FastAPI cũng hỗ trợ xây dựng các API theo mô hình RESTful. Trong đồ án, API được sử dụng để thực hiện những thao tác mà ứng dụng di động chủ động gửi yêu cầu tới máy chủ, chẳng hạn gửi ảnh, gửi âm thanh, tạo phiên, lấy thông tin cấu hình hoặc gửi yêu cầu xử lý. 

Ngoài HTTP/HTTPS, FastAPI hỗ trợ WebSocket thông qua nền tảng Starlette. WebSocket cho phép thiết lập một kênh giao tiếp hai chiều giữa client và server. Sau khi kết nối được thiết lập, server có thể chủ động gửi dữ liệu tới ứng dụng khi xuất hiện sự kiện cần phản hồi. 

FastAPI kết hợp với Pydantic cũng cho phép định nghĩa cấu trúc dữ liệu đầu vào và đầu ra. Việc kiểm tra dữ liệu tại tầng API giúp phát hiện sớm các trường hợp thiếu trường, sai kiểu dữ liệu hoặc không đúng cấu trúc trước khi dữ liệu được chuyển sang các bước xử lý tiếp theo. 

Một đặc điểm khác là FastAPI hỗ trợ chuẩn OpenAPI và cung cấp giao diện Swagger UI. Điều này giúp nhóm phát triển quan sát các endpoint, tham số và cấu trúc dữ liệu, đồng thời thuận tiện kiểm tra API trong quá trình phát triển. 

## c) Ưu điểm

FastAPI phù hợp với hệ thống có nhiều hoạt động giao tiếp mạng nhờ khả năng hỗ trợ xử lý bất đồng bộ. Cơ chế kiểm tra dữ liệu bằng Pydantic giúp tăng tính nhất quán giữa dữ liệu mà client gửi lên và dữ liệu mà server xử lý. 

Khả năng hỗ trợ WebSocket cũng là một ưu điểm quan trọng đối với đồ án. Hệ thống có những trường hợp server cần chủ động gửi thông báo tới ứng dụng, vì vậy việc duy trì một kênh giao tiếp hai chiều giúp giảm sự phụ thuộc vào việc client phải liên tục gửi request để kiểm tra trạng thái. 

Ngoài ra, khả năng tự động tạo tài liệu OpenAPI và Swagger UI giúp nhóm dễ dàng kiểm thử và theo dõi giao diện API trong quá trình phát triển. 

## d) Nhược điểm

FastAPI tập trung chủ yếu vào việc xây dựng API và các thành phần giao tiếp phía server nên đối với những chức năng đặc thù, nhóm có thể cần bổ sung thêm thư viện hoặc tự triển khai các thành phần cần thiết. 

Bên cạnh đó, cơ chế bất đồng bộ của FastAPI không tự động giải quyết các tác vụ tính toán nặng. Những tác vụ AI có thời gian xử lý lớn cần được tổ chức phù hợp, chẳng hạn thông qua worker hoặc cơ chế xử lý nền, nhằm tránh ảnh hưởng tới khả năng tiếp nhận các yêu cầu khác. 

## e) Lý do lựa chọn

FastAPI và Uvicorn được lựa chọn vì phù hợp với mô hình giao tiếp của hệ thống. Đồ án cần một tầng server có khả năng cung cấp API để nhận dữ liệu từ Mobile, đồng thời hỗ trợ WebSocket để phục vụ giao tiếp hai chiều theo thời gian thực. 

Ngoài ra, FastAPI được xây dựng trong hệ sinh thái Python nên có khả năng tích hợp thuận tiện với các thư viện xử lý dữ liệu và AI được sử dụng ở phía Server. Sự kết hợp giữa FastAPI và Uvicorn giúp kiến trúc giao tiếp của hệ thống được tổ chức rõ ràng và phù hợp với phạm vi của đồ án. 

## 2.2. Phía Mobile

## 2.2.1. Ngôn ngữ lập trình Dart

## a) Giới thiệu

Dart là ngôn ngữ lập trình hướng đối tượng và định kiểu tĩnh do Google phát triển, đồng thời là ngôn ngữ lập trình chính được sử dụng trong Flutter. Trong đồ án, Dart được sử dụng để xây dựng logic của ứng dụng di động, quản lý tương tác người dùng, xử lý dữ liệu, điều phối camera và microphone, thực hiện giao tiếp với Server và tiếp nhận kết quả xử lý. 

Ứng dụng Mobile có vai trò là thành phần tương tác trực tiếp với người dùng. Khi người dùng thực hiện một thao tác, Dart điều phối quá trình thu nhận dữ liệu từ thiết bị, gửi dữ liệu tới Server và xử lý kết quả trả về. Đối với các chức năng phụ thuộc vào AI phía Server, ứng dụng cần duy trì kết nối mạng để gửi dữ liệu và nhận kết quả. 

## b) Đặc điểm

Dart sử dụng cơ chế định kiểu tĩnh, cho phép trình biên dịch kiểm tra nhiều vấn đề liên quan đến kiểu dữ liệu trong quá trình biên dịch. Đặc điểm này giúp kiểm soát tốt hơn cấu trúc dữ liệu trong ứng dụng, đặc biệt khi ứng dụng phải xử lý dữ liệu nhận từ API. 

Dart hỗ trợ hai cơ chế biên dịch chính là JIT và AOT. Trong quá trình phát triển, JIT hỗ trợ Hot Reload, cho phép lập trình viên quan sát nhanh các thay đổi trong mã nguồn. Trong quá trình phát hành, AOT cho phép biên dịch mã Dart thành mã máy phù hợp với nền tảng mục tiêu. 

Dart cũng hỗ trợ Sound Null Safety, giúp phân biệt các giá trị có thể nhận null và các giá trị không được phép null. Trình biên dịch có thể phát hiện nhiều trường hợp sử dụng giá trị null không hợp lệ trước khi ứng dụng chạy. 

Bên cạnh đó, Dart cung cấp Future, async/await và Event Loop để xử lý các tác vụ bất đồng bộ. Các cơ chế này phù hợp với những thao tác như gửi request, chờ response hoặc giao tiếp WebSocket. Dart cũng cung cấp Isolate cho các trường hợp cần thực hiện những công việc độc lập với vùng nhớ riêng. 

## c) Ưu điểm

Dart có cú pháp tương đối rõ ràng, hỗ trợ kiểm tra kiểu dữ liệu và được tích hợp chặt chẽ với Flutter. JIT và Hot Reload hỗ trợ quá trình phát triển nhanh, trong khi AOT phục vụ quá trình xây dựng phiên bản phát hành. 

Cơ chế bất đồng bộ của Dart cũng phù hợp với ứng dụng thường xuyên phải giao tiếp với Server. Việc gửi hình ảnh, gửi âm thanh, nhận kết quả hoặc duy trì kết nối WebSocket đều có thể được tổ chức thông qua các cơ chế bất đồng bộ mà không làm gián đoạn luồng tương tác chính của ứng dụng. 

## d) Nhược điểm

Hệ sinh thái Dart độc lập nhỏ hơn một số ngôn ngữ phổ biến khác. Phần lớn hệ sinh thái hiện được sử dụng cùng Flutter để phát triển ứng dụng đa nền tảng. 

Đối với những chức năng cần tương tác sâu với phần cứng hoặc API riêng của Android/iOS, ứng dụng có thể cần sử dụng plugin hoặc mã native thông qua cơ chế phù hợp. 

## e) Lý do lựa chọn

Dart được lựa chọn chủ yếu do tích hợp trực tiếp với Flutter và cung cấp các cơ chế phù hợp với ứng dụng di động có nhiều thao tác bất đồng bộ. Việc sử dụng Dart giúp nhóm có thể xây dựng giao diện, logic ứng dụng và các luồng giao tiếp với Server trong cùng một hệ sinh thái. 

## 2.2.2. Framework Flutter

## a) Giới thiệu

Flutter là bộ công cụ phát triển ứng dụng đa nền tảng mã nguồn mở do Google phát triển, sử dụng Dart làm ngôn ngữ lập trình chính. Flutter cho phép xây dựng ứng dụng từ một cơ sở mã nguồn chung cho các nền tảng như Android và iOS. 

Trong đồ án, Flutter đảm nhiệm phần ứng dụng Mobile, bao gồm xây dựng giao diện, tiếp nhận tương tác từ người dùng, truy cập camera và microphone thông qua các thư viện hỗ trợ, giao tiếp với Server, nhận kết quả xử lý và cung cấp phản hồi cho người dùng. 

Đối với bài toán hỗ trợ người khiếm thị, Flutter còn được sử dụng để xây dựng giao diện có khả năng phối hợp với các cơ chế Accessibility của hệ điều hành. Tuy nhiên, khả năng tiếp cận không tự động được bảo đảm chỉ bằng việc sử dụng Flutter mà phụ thuộc vào cách giao diện được thiết kế và cấu hình. 

## b) Đặc điểm

Flutter xây dựng giao diện dựa trên mô hình Widget. Các thành phần giao diện được tổ chức thành một cây Widget, trong đó mỗi Widget đảm nhiệm một thành phần hoặc một nhóm chức năng nhất định. Cách tổ chức này giúp giao diện được chia thành các thành phần nhỏ, có thể tái sử dụng và bảo trì. 

Flutter sử dụng engine đồ họa riêng để thực hiện quá trình rendering. Điều này giúp nhóm phát triển kiểm soát tương đối nhất quán cách giao diện được xây dựng và hiển thị. 

Một tính năng quan trọng của Flutter là Hot Reload. Trong quá trình phát triển, lập trình viên có thể chỉnh sửa mã nguồn và nhanh chóng quan sát kết quả trên ứng dụng đang chạy. Điều này đặc biệt thuận tiện khi xây dựng và điều chỉnh giao diện. 

Đối với bài toán hỗ trợ người khiếm thị, Flutter cung cấp cơ chế Semantics để mô tả các thành phần giao diện cho hệ thống hỗ trợ tiếp cận. Các thông tin như nhãn, vai trò và trạng thái của thành phần có thể được cung cấp cho trình đọc màn hình. Trên Android, ứng dụng có thể phối hợp với TalkBack; trên iOS, ứng dụng có thể phối hợp với VoiceOver. 

Flutter cũng có khả năng kết hợp với các plugin để truy cập camera, microphone và hệ thống âm thanh. Trong trường hợp một chức năng không được plugin cung cấp đầy đủ, có thể cần sử dụng Platform Channels để giao tiếp với mã native của nền tảng. 

## c) Ưu điểm

Flutter cho phép phát triển ứng dụng đa nền tảng với một cơ sở mã nguồn chung, giúp giảm công sức xây dựng và bảo trì khi hệ thống cần hỗ trợ nhiều nền tảng. 

Mô hình Widget giúp giao diện được tổ chức thành các thành phần có thể tái sử dụng. Hot Reload hỗ trợ quá trình phát triển nhanh và thuận tiện cho việc kiểm tra giao diện. 

Đối với đồ án, khả năng kết hợp Flutter với Semantics và hệ thống đọc màn hình là một ưu điểm quan trọng. Đây là cơ sở để xây dựng giao diện hướng tới nhóm người dùng khiếm thị, trong đó âm thanh và khả năng tiếp cận đóng vai trò quan trọng hơn so với việc chỉ phụ thuộc vào hiển thị trực quan. 

## d) Nhược điểm

Ứng dụng Flutter có thể có dung lượng lớn hơn một số ứng dụng native đơn thuần do cần đi kèm các thành phần của Flutter. 

Ngoài ra, các chức năng tương tác sâu với phần cứng như camera, microphone hoặc quản lý âm thanh có thể phụ thuộc vào plugin. Nếu plugin không đáp ứng đầy đủ yêu cầu, nhóm có thể phải bổ sung mã native hoặc sử dụng Platform Channels. 

## e) Lý do lựa chọn

Flutter được lựa chọn vì phù hợp với yêu cầu xây dựng ứng dụng di động đa nền tảng có khả năng xử lý hình ảnh, âm thanh và giao tiếp mạng. Đặc biệt, cơ chế Widget và Semantics tạo điều kiện thuận lợi cho việc xây dựng giao diện hướng tới khả năng tiếp cận của người khiếm thị. 

## 2.4. Công nghệ giao tiếp giữa Mobile và Server

## 2.4.1. HTTPS – Giao tiếp giữa ứng dụng và máy chủ

## a) Giới thiệu

HTTPS (HyperText Transfer Protocol Secure) là giao thức truyền tải siêu văn bản an toàn, được xây dựng trên nền HTTP kết hợp với TLS (Transport Layer Security) nhằm bảo vệ dữ liệu trao đổi giữa client và server. HTTP hoạt động theo mô hình yêu cầu – phản hồi (request–response), trong đó client gửi yêu cầu đến server và nhận lại phản hồi tương ứng. Khi sử dụng HTTPS, dữ liệu được bảo vệ trên đường truyền thông qua cơ chế mã hóa của TLS, giúp hạn chế nguy cơ bị nghe lén hoặc sửa đổi trái phép. Đồng thời, chứng chỉ số TLS cho phép client xác minh danh tính của server, góp phần bảo đảm tính xác thực trong quá trình giao tiếp. 

HTTPS cung cấp ba thuộc tính an toàn cơ bản, bao gồm tính bảo mật (Confidentiality), tính toàn vẹn (Integrity) và tính xác thực (Authentication). Tính bảo mật giúp ngăn chặn bên thứ ba đọc nội dung dữ liệu trên đường truyền; tính toàn vẹn hỗ trợ phát hiện dữ liệu bị thay đổi trong quá trình truyền; tính xác thực cho phép client kiểm tra danh tính server thông qua chứng chỉ số hợp lệ. Trong ứng dụng Hina, HTTPS được sử dụng để giao tiếp giữa Mobile và Backend đối với các yêu cầu quản lý phiên, chẳng hạn như khởi tạo phiên, xác thực thông tin phiên và yêu cầu kết thúc phiên. 

## b) Đặc điểm

HTTPS sử dụng mô hình giao tiếp request–response, trong đó mỗi yêu cầu được gửi từ client đến server và nhận về một phản hồi tương ứng. Giao thức hỗ trợ nhiều phương thức HTTP như GET, POST, PUT, PATCH và DELETE, tùy theo mục đích của từng API. Dữ liệu trao đổi có thể sử dụng các định dạng như JSON hoặc dữ liệu nhị phân theo thiết kế của hệ thống. Bên cạnh đó, HTTPS sử dụng TLS để bảo vệ dữ liệu trên đường truyền và xác minh danh tính server thông qua chứng chỉ số. 

Về quản lý trạng thái, HTTP về bản chất là giao thức không trạng thái, nghĩa là mỗi yêu cầu được xử lý độc lập ở tầng giao thức. Nếu hệ thống cần duy trì trạng thái đăng nhập hoặc phiên tương tác, thông tin phiên phải được quản lý thông qua token, mã phiên hoặc các cơ chế tương ứng ở tầng ứng dụng. Vì vậy, HTTPS phù hợp với các thao tác có yêu cầu và phản hồi rõ ràng, nhưng không được thiết kế chuyên biệt cho việc trao đổi dữ liệu hai chiều liên tục. 

## c) Ưu điểm

HTTPS có ưu điểm nổi bật là hỗ trợ bảo vệ dữ liệu trong quá trình truyền thông qua cơ chế mã hóa và kiểm tra tính toàn vẹn của TLS. Giao thức có tính phổ biến cao, được hỗ trợ rộng rãi trên các nền tảng phát triển ứng dụng và hệ thống máy chủ, giúp quá trình tích hợp giữa Mobile và Backend thuận tiện hơn. Ngoài ra, mô hình request–response rõ ràng giúp việc thiết kế API, kiểm thử chức năng, theo dõi lỗi và bảo trì hệ thống trở nên thuận lợi. HTTPS cũng có thể kết hợp với các cơ chế xác thực, phân quyền và kiểm tra dữ liệu đầu vào nhằm tăng cường an toàn cho hệ thống. 

## d) Nhược điểm

Mặc dù có nhiều ưu điểm, HTTPS vẫn có thể phát sinh độ trễ do quá trình truyền dữ liệu, xử lý yêu cầu và thiết lập kết nối. Nếu phải thiết lập một kết nối mới, hệ thống có thể phát sinh thêm chi phí bắt tay TLS. Bên cạnh đó, mô hình request–response yêu cầu client chủ động gửi yêu cầu để nhận dữ liệu, do đó chưa tối ưu đối với các tình huống cần trao đổi dữ liệu hai chiều liên tục và phản hồi theo thời gian thực. HTTPS cũng không tự bảo đảm an toàn cho toàn bộ hệ thống nếu Backend không thực hiện đầy đủ các biện pháp như xác thực, phân quyền, kiểm tra dữ liệu đầu vào và bảo vệ thông tin nhạy cảm. 

## e) Lý do lựa chọn

HTTPS được lựa chọn cho ứng dụng nhằm bảo vệ dữ liệu trao đổi giữa ứng dụng Mobile và Backend, đồng thời cung cấp phương thức giao tiếp phù hợp cho các nghiệp vụ quản lý phiên. Những thao tác như khởi tạo phiên, xác thực thông tin và yêu cầu kết thúc phiên có thể được triển khai thông qua các API sử dụng HTTPS. Cách tiếp cận này giúp phân tách rõ các yêu cầu quản lý phiên với luồng trao đổi dữ liệu thời gian thực, từ đó đơn giản hóa việc thiết kế, kiểm thử và bảo trì hệ thống. Việc sử dụng HTTPS kết hợp với các cơ chế xác thực và kiểm soát truy cập phù hợp cũng góp phần nâng cao mức độ an toàn trong quá trình vận hành ứng dụng. 

## 2.4.2. WebSocket Secure (WSS) – Giao tiếp hai chiều thời gian thực

## a) Giới thiệu

WebSocket là giao thức cho phép thiết lập kênh giao tiếp hai chiều giữa client và server trên một kết nối được duy trì liên tục. Sau khi quá trình bắt tay thiết lập kết nối thành công, cả client và server đều có thể chủ động gửi dữ liệu cho phía còn lại mà không cần tạo một yêu cầu HTTP mới cho từng thông điệp. WSS (WebSocket Secure) là WebSocket hoạt động trên kết nối được bảo vệ bằng TLS, sử dụng địa chỉ có tiền tố wss:// nhằm bảo vệ dữ liệu trao đổi trên đường truyền. 

Trong ứng dụng, WSS được sử dụng để trao đổi dữ liệu trong quá trình tương tác giữa người dùng và Backend. Mobile có thể gửi dữ liệu âm thanh và các frame hình ảnh khi yêu cầu cần thông tin thị giác. Backend tiếp nhận dữ liệu, thực hiện xử lý và gửi kết quả về Mobile thông qua kết nối đã thiết lập. 

## b) Đặc điểm

WSS hỗ trợ giao tiếp hai chiều trên cùng một kết nối, cho phép cả client và server chủ động gửi dữ liệu trong suốt thời gian kết nối còn hoạt động. Giao thức hỗ trợ truyền thông điệp dạng văn bản và dữ liệu nhị phân, phù hợp với việc trao đổi thông tin điều khiển, dữ liệu âm thanh và hình ảnh. Do kết nối được duy trì qua nhiều lượt tương tác, hệ thống không cần thực hiện lại quá trình bắt tay cho từng thông điệp như khi liên tục tạo các kết nối mới. 

Tuy nhiên, WSS chỉ cung cấp cơ chế truyền dữ liệu hai chiều, không tự quy định cấu trúc dữ liệu nghiệp vụ hoặc cách xử lý các yêu cầu AI. Vì vậy, ứng dụng và Backend cần thống nhất định dạng thông điệp, mã phiên, mã lượt tương tác và quy tắc phản hồi. Hệ thống cũng cần có cơ chế quản lý kết nối, phát hiện timeout, xử lý mất mạng và thiết lập lại kết nối khi cần thiết để bảo đảm quá trình tương tác diễn ra ổn định. 

## c) Ưu điểm

WSS có ưu điểm là hỗ trợ trao đổi dữ liệu hai chiều liên tục, phù hợp với các ứng dụng cần tương tác thời gian thực. Việc duy trì kết nối giúp hạn chế chi phí thiết lập kết nối lặp lại cho từng thông điệp và tạo điều kiện để server chủ động gửi phản hồi về Mobile. Khả năng truyền dữ liệu nhị phân cũng thuận tiện cho việc trao đổi audio và frame hình ảnh trong ứng dụng. Ngoài ra, việc sử dụng TLS giúp bảo vệ dữ liệu trên đường truyền, góp phần tăng cường tính bảo mật trong quá trình trao đổi giữa ứng dụng và máy chủ. 

## d) Nhược điểm

WSS yêu cầu hệ thống quản lý kết nối lâu dài, bao gồm trạng thái kết nối, timeout, đóng kết nối và khôi phục kết nối sau khi mạng bị gián đoạn. Khi số lượng kết nối đồng thời tăng cao, Backend cần có khả năng quản lý tài nguyên và xử lý các kết nối phù hợp. Nếu kết nối bị ngắt trong quá trình truyền dữ liệu, ứng dụng cần xác định yêu cầu nào đã hoàn thành, yêu cầu nào cần gửi lại và kết quả nào phải loại bỏ để tránh xử lý trùng lặp. Bên cạnh đó, việc truyền audio và hình ảnh có thể tiêu tốn đáng kể băng thông, đặc biệt khi gửi dữ liệu với tần suất cao hoặc sử dụng frame có dung lượng lớn. 

## e) Lý do lựa chọn

WSS được lựa chọn cho ứng dụng vì ứng dụng cần trao đổi dữ liệu âm thanh, hình ảnh và kết quả xử lý giữa Mobile với Backend trong quá trình tương tác. Việc duy trì kết nối hai chiều cho phép Mobile gửi dữ liệu đầu vào và nhận phản hồi trên cùng một kênh giao tiếp, phù hợp với yêu cầu trao đổi dữ liệu liên tục và giảm độ trễ phát sinh do thiết lập kết nối lặp lại. 

Bên cạnh đó, WSS hỗ trợ truyền dữ liệu nhị phân và bảo vệ dữ liệu bằng TLS, đáp ứng nhu cầu truyền audio và frame hình ảnh khi cần. Khi kết hợp với cơ chế quản lý phiên, kiểm tra trạng thái kết nối, xử lý timeout và khôi phục kết nối, WSS tạo nền tảng phù hợp để triển khai luồng tương tác giữa người dùng và Backend. 

## 2.6. Công cụ phát triển và thư viện bổ trợ

## 2.6.1. Hệ thống quản lý mã nguồn Git

Git được sử dụng để quản lý phiên bản phân tán cho cả mã nguồn Mobile và Server. Công cụ này cho phép theo dõi lịch sử thay đổi qua commit, phân nhánh phát triển (branching) độc lập và khôi phục mã nguồn khi cần thiết, giúp giảm rủi ro mất mã nguồn và nâng cao hiệu quả làm việc nhóm. 

## 2.6.2. Môi trường phát triển ứng dụng Mobile

Android Studio và Visual Studio Code được lựa chọn làm môi trường lập trình Flutter. Android Studio cung cấp hệ thống công cụ chuyên sâu về Android SDK, Emulator và quản lý thiết bị. Visual Studio Code mang lại môi trường làm việc nhẹ hơn với hệ sinh thái extension phong phú cho Dart và Flutter. Cả hai môi trường đều hỗ trợ cơ chế Hot Reload, debug và kiểm tra theo dõi log hệ thống theo thời gian thực. 

## 2.6.3. Môi trường phát triển phía Server

PyCharm và Visual Studio Code được áp dụng để phát triển mã nguồn Python và FastAPI. Các IDE này hỗ trợ quản lý dự án, gợi ý cú pháp, kiểm tra lỗi và debug luồng xử lý từ khi tiếp nhận request đến khi điều phối qua các mô-đun AI. Quá trình phát triển yêu cầu thống nhất cấu hình môi trường và các gói thư viện phụ thuộc. 

## 2.6.4. Công cụ kiểm thử API Postman

Postman hỗ trợ kiểm thử độc lập các endpoint phía Server trước khi tích hợp vào Mobile. Công cụ cho phép khởi tạo request, tùy chỉnh header/body, tham số và phân tích response. Nhờ đó, nhóm phát triển có thể kiểm tra tính chính xác của dữ liệu và phát hiện sớm các lỗi giao tiếp API. 

## 2.6.5. Nền tảng đóng gói Docker

Docker được áp dụng để đóng gói ứng dụng Server cùng các phụ thuộc vào container. Việc này đảm bảo tính thống nhất của môi trường thực thi giữa giai đoạn phát triển và triển khai, đồng thời tối ưu hóa quá trình khởi tạo Server trên các hạ tầng khác nhau. 

## 2.7. Tổng kết chương

Kiến trúc hệ thống được xây dựng theo mô hình phân tách trách nhiệm giữa Mobile và Server. Phía Server sử dụng Python, FastAPI và Uvicorn làm nền tảng xử lý logic, điều phối các mô-đun AI và cung cấp API. Phía Mobile sử dụng Dart và Flutter để phát triển giao diện đa nền tảng, thu nhận dữ liệu đa phương tiện và tương tác với các tính năng hỗ trợ tiếp cận (Semantics). 

Về giao thức và bảo mật, hệ thống kết hợp HTTPS cho các tương tác API dạng request-response và WSS cho luồng thông báo thời gian thực, toàn bộ được mã hóa bằng TLS. Cơ chế xác thực sử dụng JWT ngắn hạn chứa session_id với chữ ký HMAC-SHA256 lưu trữ phía Server, kết hợp kiểm soát trạng thái phiên trong bộ nhớ nhằm cho phép thu hồi linh hoạt. 

Phía Mobile áp dụng nguyên tắc lưu trữ tối giản: chỉ lưu cấu hình ứng dụng bằng shared_preferences và giữ token trong bộ nhớ tạm mà không sử dụng cơ sở dữ liệu cục bộ cho dữ liệu AI. Các chức năng nhận diện phụ thuộc hoàn toàn vào kết nối mạng và sẽ tạm dừng khi mất liên lạc với Server. Sự phối hợp giữa các công cụ phát triển (Git, IDEs, Postman, Docker) giúp đảm bảo quy trình phát triển, kiểm thử và triển khai đồng bộ. 

## 3. Thiết kế kiến trúc

## 3.1. Client (Mobile)

## 3.1.1. Tổng quan

Ứng dụng Mobile đóng vai trò là giao diện tương tác trực tiếp với người dùng trên điện thoại thông minh. Thiết bị sử dụng camera sau để ghi nhận hình ảnh môi trường, microphone để tiếp nhận câu hỏi giọng nói và loa để phản hồi kết quả. Đồng thời, Mobile đảm nhiệm việc quản lý giao diện, hiển thị trạng thái hệ thống và điều phối vòng đời phiên làm việc. 

Ứng dụng được thiết kế theo hướng không xử lý các mô hình trí tuệ nhân tạo trực tiếp trên thiết bị. Toàn bộ chuỗi mô hình như ASR, NLU, OCR, Detection, Captioning, VQA và TTS đều được triển khai tập trung tại Server. Mobile chỉ tập trung thu nhận, chuẩn hóa và đóng gói dữ liệu để gửi lên Server, sau đó tiếp nhận và chuyển giao kết quả thành phản hồi dạng âm thanh hoặc hình ảnh cho người dùng. Mô hình này giúp tối ưu hóa tài nguyên tính toán trên điện thoại, đồng thời đảm bảo tính đồng bộ với kiến trúc tổng thể của đồ án. 

## 3.1.2. Các thành phần chính của Mobile

Ứng dụng Mobile được thiết kế theo kiến trúc phân chia thành các khối chức năng độc lập, trong đó Session Controller đóng vai trò điều phối trung tâm. Các khối còn lại đảm nhiệm những nhiệm vụ chuyên biệt như tương tác với người dùng, kích hoạt bằng giọng nói, thu thập dữ liệu âm thanh và hình ảnh, truyền thông với Backend, phát kết quả bằng âm thanh và quản lý quyền truy cập tài nguyên hệ thống. Cách tổ chức này giúp phân tách rõ trách nhiệm giữa các thành phần, nâng cao khả năng bảo trì, kiểm thử và mở rộng ứng dụng. Các thành phần chính của Mobile được trình bày như sau: 

## a) UI & Accessibility

UI & Accessibility là khối cung cấp giao diện tương tác giữa người dùng và ứng dụng, đồng thời tích hợp các chức năng hỗ trợ tiếp cận dành cho người khiếm thị. Khối này chịu trách nhiệm hiển thị trạng thái hoạt động của ứng dụng, cung cấp các thao tác điều khiển cơ bản và hướng dẫn người dùng trong quá trình thiết lập, sử dụng hệ thống. Các trạng thái như khởi tạo ứng dụng, sẵn sàng tiếp nhận yêu cầu, đang xử lý, mất kết nối và kết thúc phiên được thể hiện thông qua giao diện và các phương thức phản hồi phù hợp. Bên cạnh đó, khối này được thiết kế tương thích với tính năng TalkBack trên Android, thông qua việc cung cấp nhãn truy cập, mô tả thành phần giao diện và hỗ trợ điều hướng bằng các phương thức trợ năng. 

Về quan hệ tương tác, UI & Accessibility tiếp nhận thao tác của người dùng và chuyển các sự kiện điều khiển đến Session Controller. Đồng thời, khối nhận thông tin trạng thái từ Session Controller để cập nhật giao diện và hướng dẫn người dùng thực hiện các bước tiếp theo. Đối với những thông báo cần phát bằng giọng nói, khối phối hợp với Audio Playback để truyền tải thông tin một cách rõ ràng và dễ tiếp nhận. Thiết kế này bảo đảm giao diện không trực tiếp xử lý nghiệp vụ phiên hoặc giao tiếp với Backend, mà tập trung vào nhiệm vụ tương tác và hỗ trợ tiếp cận. 

## b) Khối Session Controller (Bộ điều phối phiên)

Session Controller là khối điều phối trung tâm của ứng dụng Mobile, chịu trách nhiệm quản lý trạng thái phiên giao tiếp và kiểm soát trình tự thực hiện của các chức năng. Khối này tổ chức hoạt động của ứng dụng theo các trạng thái xác định, bao gồm khởi tạo, sẵn sàng, tiếp nhận yêu cầu, thu thập dữ liệu, gửi yêu cầu, chờ kết quả, phát phản hồi và kết thúc phiên. Việc quản lý trạng thái giúp bảo đảm các khối chức năng được kích hoạt đúng thời điểm, tránh thu thập dữ liệu không cần thiết, hạn chế xử lý trùng lặp và duy trì tính nhất quán giữa các lượt giao tiếp. 

Khi nhận được sự kiện đánh thức từ Voice Activation hoặc thao tác điều khiển từ UI & Accessibility, Session Controller kiểm tra trạng thái hiện tại và điều kiện hoạt động trước khi khởi tạo hoặc tiếp tục phiên. Trong quá trình tiếp nhận yêu cầu, khối điều khiển Audio Capture thu âm, yêu cầu Camera Manager cung cấp hình ảnh khi cần thiết và phối hợp với Network Manager để truyền dữ liệu đến Backend. Khi nhận được kết quả xử lý hợp lệ, Session Controller yêu cầu Audio Playback phát âm thanh phản hồi. Sau khi quá trình phát hoàn tất, khối chuyển phiên về trạng thái sẵn sàng để tiếp nhận yêu cầu tiếp theo hoặc thực hiện kết thúc phiên theo lệnh của người dùng. 

Ngoài chức năng điều phối, Session Controller còn chịu trách nhiệm xử lý timeout, quản lý mã phiên và mã yêu cầu, loại bỏ phản hồi không còn hợp lệ và phối hợp xử lý các lỗi phát sinh trong quá trình giao tiếp. Khi xảy ra lỗi không thể phục hồi, khối chuyển ứng dụng sang trạng thái lỗi phù hợp, yêu cầu phát thông báo cho người dùng và giải phóng các tài nguyên liên quan. Nhờ đó, Session Controller bảo đảm luồng hoạt động giữa các thành phần được thực hiện có kiểm soát và thống nhất. 

## c) Khối Voice Activation (Kích hoạt bằng giọng nói)

Khối Voice Activation đảm nhiệm vai trò phát hiện từ khóa đánh thức (wake-word), cho phép người dùng kích hoạt ứng dụng hoàn toàn bằng giọng nói mà không cần thao tác trực tiếp trên màn hình thiết bị. Ngay khi ghi nhận tín hiệu hợp lệ, Voice Activation sẽ phát sự kiện đánh thức tới Session Controller để kiểm tra điều kiện hệ thống và khởi tạo phiên làm việc mới. 

## d) Khối Audio Capture

Khối thu thập âm thanh (Audio Capture) chịu trách nhiệm tiếp nhận và chuẩn bị dữ liệu giọng nói từ người dùng để chuyển đến Backend xử lý. Dưới sự điều phối của khối Session Controller, khối này tiến hành kiểm tra trạng thái microphone, khởi tạo tiến trình ghi âm và thu thập tín hiệu âm thanh đầu vào. Để tối ưu hóa quá trình xử lý, khối ứng dụng kỹ thuật phát hiện hoạt động giọng nói (Voice Activity Detection – VAD) nhằm tự động nhận diện thời điểm bắt đầu phát ngôn, khoảng lặng và điểm kết thúc của một lượt lời. 

Sau khi hoàn tất quá trình thu thập, dữ liệu âm thanh được chuẩn hóa và đóng gói theo các thông số kỹ thuật tương thích với Backend, bao gồm tần số lấy mẫu, số kênh và định dạng mã hóa. Dữ liệu sau đó được chuyển giao thông qua Network Manager. Khi yêu cầu hoàn tất, phát sinh lỗi hoặc phiên làm việc kết thúc, Audio Capture chịu trách nhiệm dừng tiến trình và giải phóng tài nguyên hệ thống, qua đó vừa đảm bảo tính bảo mật và khả năng tiết kiệm pin, vừa nâng cao tính ổn định cho toàn bộ ứng dụng. 

## e) Khối Camera Manager

Camera Manager là khối chịu trách nhiệm quản lý camera và thu thập hình ảnh môi trường xung quanh phục vụ các chức năng hỗ trợ người khiếm thị. Khối này thực hiện việc kiểm tra quyền truy cập camera, khởi tạo và quản lý tài nguyên camera, chụp ảnh hoặc lấy các khung hình (frame) theo yêu cầu của Session Controller. Để tối ưu hiệu năng và giảm lượng dữ liệu truyền qua mạng, hình ảnh có thể được tiền xử lý ở mức cần thiết, chẳng hạn điều chỉnh kích thước, nén ảnh hoặc chuyển đổi định dạng trước khi gửi. Mỗi frame có thể được gắn thông tin thời gian và mã lượt yêu cầu nhằm hỗ trợ liên kết dữ liệu hình ảnh với đoạn âm thanh tương ứng. 

Trong tiến trình vận hành, Camera Manager chỉ thực hiện thu thập dữ liệu hình ảnh khi nhận được lệnh điều phối từ Session Controller và điều kiện quyền truy cập hợp lệ. Dữ liệu sau khi hoàn tất công đoạn chuẩn bị sẽ được chuyển giao tới Network Manager để truyền tải về máy chủ Backend. Khi yêu cầu hoàn tất, phát sinh lỗi hoặc phiên làm việc kết thúc, Camera Manager chịu trách nhiệm dừng tiến trình và giải phóng tài nguyên hệ thống, qua đó vừa đảm bảo tính bảo mật và khả năng tiết kiệm pin, vừa nâng cao tính ổn định cho toàn bộ ứng dụng. 

## f) Khối Network Manager (Quản lý truyền thông mạng)

Khối Network Manager đóng vai trò là tầng giao tiếp trung gian, đảm nhiệm nhiệm vụ thiết lập, duy trì và quản lý toàn bộ các luồng truyền tải dữ liệu giữa ứng dụng di động và hệ thống máy chủ Backend. Thành phần này trực tiếp điều phối các thức giao thức mạng tiêu chuẩn nhằm bảo đảm tính toàn vẹn, bảo mật và độ tin cậy của dữ liệu truyền qua môi trường Internet. Cụ thể, Network Manager ứng dụng giao thức HTTPS đối với các tác vụ quản lý phiên, xác thực người dùng và các truy vấn dữ liệu dạng request-response. Đồng thời, đối với luồng tương tác hội thoại đòi hỏi phản hồi theo thời gian thực, khối khởi tạo và duy trì kênh kết nối hai chiều bảo mật thông qua giao thức WebSocket Secure (WSS). 

Về mặt chức năng đóng gói và truyền tải, Network Manager tiếp nhận dữ liệu âm thanh từ Audio Capture và dữ liệu hình ảnh từ Camera Manager, sau đó tiến hành chuẩn hóa cấu trúc dữ liệu theo định dạng giao thức được quy định trước khi gửi lên máy chủ Backend. Nhằm phục vụ công tác đối chiếu và kiểm soát thứ tự xử lý, mỗi gói tin đều được gắn kèm các trường dữ liệu định danh như mã phiên (session ID), mã lượt yêu cầu (request ID), nhãn thời gian (timestamp) và loại dữ liệu. Ở chiều ngược lại, khi tiếp nhận dữ liệu phản hồi âm thanh, trạng thái xử lý hoặc mã lỗi từ Backend, khối tiến hành giải mã, kiểm tra tính hợp lệ và chuyển giao trực tiếp cho Session Controller để điều phối các bước tiếp theo. 

Bên cạnh đó, Network Manager đảm nhiệm cơ chế kiểm soát lỗi và quản lý sự cố mạng chặt chẽ. Khối chủ động phát hiện và xử lý các tình huống bất lợi như mất kết nối, thời gian chờ vượt giới hạn (timeout), gián đoạn đường truyền hoặc lỗi xác thực từ máy chủ. Trong các trường hợp sự cố, khối triển khai quy trình kết nối lại tự động hoặc phát cảnh báo lỗi tiêu chuẩn về Session Controller để chuyển đổi trạng thái ứng dụng một cách an toàn. Việc đóng gói độc lập toàn bộ logic giao tiếp mạng trong Network Manager giúp giảm thiểu sự phụ thuộc trực tiếp của các khối thu thập dữ liệu và phát âm thanh vào hạ tầng truyền thông, qua đó nâng cao tính mô-đun và khả năng bảo trì của hệ thống. 

## g) Khối Audio Playback

Khối Audio Playback đảm nhiệm vai trò phát các phản hồi bằng âm thanh nhằm truyền đạt kết quả xử lý từ Backend đến người dùng. Khi Network Manager tiếp nhận dữ liệu âm thanh phản hồi hợp lệ, Session Controller sẽ điều phối khối Audio Playback giải mã và phát nội dung theo định dạng chuẩn. Khối chịu trách nhiệm quản lý toàn bộ trạng thái phát (bắt đầu, tạm dừng, tiếp tục, hoàn tất hoặc hủy bỏ) và thông báo kết quả thực thi về Session Controller. Bên cạnh âm thanh phản hồi được tạo từ máy chủ, Audio Playback còn quản lý và phát các thông báo mẫu được lưu trữ cục bộ trên thiết bị (như trạng thái ứng dụng sẵn sàng, mất kết nối, lỗi xử lý hoặc kết thúc phiên giao tiếp). Việc duy trì các thông báo dự phòng này có ý nghĩa quan trọng giúp đảm bảo tính liên tục của giao tiếp người dùng trong các tình huống ứng dụng không thể kết nối tới Backend. 

## h) Khối Permission & Lifecycle

Permission & Lifecycle là khối chịu trách nhiệm quản lý quyền truy cập tài nguyên và theo dõi vòng đời hoạt động của ứng dụng trên thiết bị. Khối này kiểm tra và yêu cầu các quyền cần thiết như microphone và camera theo chức năng được sử dụng, đồng thời phân biệt các trạng thái cấp quyền để ứng dụng có thể hướng dẫn người dùng xử lý khi quyền bị từ chối hoặc cần được cấp lại trong phần cài đặt hệ thống. Bên cạnh đó, khối theo dõi trạng thái vòng đời ứng dụng, chẳng hạn khi ứng dụng được mở, chuyển xuống nền, quay lại tiền cảnh hoặc bị gián đoạn bởi hệ điều hành. 

Khối Permission & Lifecycle giữ vai trò quan trọng trong việc quản lý quyền truy cập tài nguyên phần cứng và giám sát trạng thái vòng đời của ứng dụng trên thiết bị di động. 

## i) Tổng kết

Tám khối chức năng trên phối hợp để hình thành luồng hoạt động thống nhất của ứng dụng Mobile. UI & Accessibility cung cấp phương thức tương tác; Voice Activation phát hiện từ khóa đánh thức; Audio Capture và Camera Manager thu thập dữ liệu đầu vào; Network Manager đảm nhiệm giao tiếp với Backend; Audio Playback phát kết quả bằng âm thanh; Permission & Lifecycle quản lý quyền và tài nguyên hệ thống. Trong toàn bộ kiến trúc, Session Controller giữ vai trò điều phối trung tâm, quyết định thời điểm kích hoạt, tạm dừng, tiếp tục hoặc kết thúc hoạt động của từng khối dựa trên trạng thái phiên. Cách phân chia này tạo cơ sở cho việc triển khai, kiểm thử và mở rộng ứng dụng theo hướng mô-đun, đồng thời phù hợp với yêu cầu tương tác bằng giọng nói của hệ thống hỗ trợ người khiếm thị. 

![image](https://cdn-mineru.openxlab.org.cn/result/2026-10-31/eb9fbad9-0cef-4ef8-aa19-6999a88b33ba/045d4efee3fd2e15581d43ab2d7e298ca1ddbe2de44d390c5ab929137077579d.jpg)



Hình 3.1.2. Sơ đồ khối chức năng của Mobile


3.2. Backend (Server) 

3.2.1. Tổng quan 

3.2.2. Các thành phần chính của Backend 

3.3. Kết nối 

3.4. Sơ đồ kiến trúc tổng thể 

3.5. Tổng kết 