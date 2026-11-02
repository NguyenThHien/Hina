Tổng quan các phần nghiên cứu cho server 

- ASR: audio ⇒ Text (Pho/Vinai) 

NLU: Text ⇒ Intent + entities (Rule-based/mô hình phân loại) 

- OCR detection: Phát hiện ảnh vùng chữ ⇒ Input cho OCR recognition (Nhận dạng ký tự) 

- Detection: Object ⇒ Chỉ dừng lại ở phát hiện vị trí đối tượng trong ảnh 

- VLM: Image captioning + VQA (Visual question captioning) 

- TTS: Text => Audio 

- Khối xử lý khoảng cách bổ trợ cho Detection 

- Khối tổng hợp kết quả để đưa ra output 

- Tiền xử lý âm thanh + hình ảnh 

- Phương thức kết nối trao đổi với mobile 

- Sau khi hiểu được intent do NLU xác định phải có một khối route để gọi đến đâu 

- Riêng phần cảnh báo nguy hiểm + vật cản nguy hiểm sẽ được diễn ra song song và ưu tiên cao nhất 

## Nhóm 1. Giao tiếp và điều phối

<table><tr><td>Service</td><td>Chức năng</td></tr><tr><td>1. API Gateway / Realtime Gateway</td><td>Tiếp nhận HTTPS và WSS từ Mobile, xác thực, quản lý kết nối và chuyển dữ liệu</td></tr><tr><td>2. Session Service</td><td>Tạo, quản lý, kết thúc phiên làm việc; quản lý trạng thái phiên</td></tr><tr><td>3. Input Preprocessing Service</td><td>Tiền xử lý audio và hình ảnh trước khi đưa vào các mô hình AI</td></tr><tr><td>4. AI Orchestrator Service</td><td>Nhận Intent + Entities, định tuyến yêu cầu đến các AI Service, điều phối xử lý song song</td></tr></table>

## Nhóm 2. Xử lý AI

<table><tr><td>Service</td><td>Input</td><td>Output</td></tr><tr><td>5. ASR Service</td><td>Audio</td><td>Text</td></tr><tr><td>6. NLU Service</td><td>Text</td><td>Intent + Entities</td></tr><tr><td>7. OCR Service</td><td>Image</td><td>Text nhận dạng được</td></tr><tr><td>8. Object Detection Service</td><td>Image</td><td>Nhãn đối tượng + Bounding Box + Confidence</td></tr><tr><td>9. Distance Estimation Service</td><td>Image + Bounding Box + thông tin camera</td><td>Khoảng cách ước lượng</td></tr><tr><td>10. VLM Service</td><td>Image + câu hỏi (nếu có)</td><td>Mô tả hình ảnh / câu trả lời</td></tr><tr><td>11. TTS Service</td><td>Text</td><td>Audio</td></tr></table>


Trong đó: 



OCR Service gồm hai bước: Text Detection (phát hiện vùng chữ) → Text Recognition (nhận dạng ký tự). 


Object Detection chỉ nhận diện đối tượng và xác định vị trí của chúng trong ảnh, chưa kết luận đối tượng có nguy hiểm hay không. 

Distance Estimation hỗ trợ xác định khoảng cách tương đối hoặc khoảng cách ước lượng, tùy mô hình và dữ liệu camera. 


Nhóm 3. Cảnh báo và tổng hợp kết quả


<table><tr><td>Service</td><td>Chức năng</td></tr><tr><td>12. Safety Monitoring Service</td><td>Giám sát nguy hiểm liên tục, đánh giá vật cần và tình huống nguy hiểm, phát cảnh báo ưu tiên cao</td></tr><tr><td>13. Result Aggregator Service</td><td>Tổng hợp kết quả từ các AI Service, chuẩn hóa nội dung và tạo phần hồi cuối cùng</td></tr></table>


Safety Monitoring Service phải chạy độc lập với luồng xử lý câu hỏi. Nghĩa là khi người dùng đang hỏi “Đây là vật gì?”, hệ thống vẫn liên tục kiểm tra vật cản phía trước. 


## Nhóm 4. Hạ tầng hỗ trợ

Đây là các thành phần hỗ trợ triển khai, không nhất thiết phải xây dựng thành microservice riêng: 

<table><tr><td>Thành phần</td><td>Vai trò</td></tr><tr><td>Redis</td><td>Lưu trạng thái phiên, cache dữ liệu tạm</td></tr><tr><td>Message Broker (tùy chơn)</td><td>Truyền sự kiện giữa các service khi cần xử lý bất đồng bộ</td></tr><tr><td>Database</td><td>Lưu nhật ký cảnh báo, thông tin phiên cần lưu lâu dài</td></tr><tr><td>Monitoring &amp; Logging</td><td>Theo dõi lỗi, hiệu năng và độ trễ</td></tr><tr><td>Model Storage</td><td>Quản lý phiên bản mô hình AI</td></tr><tr><td>Docker Compose</td><td>Triển khai và quản lý các container</td></tr></table>


Như vậy, kiến trúc đề xuất có 13 service logic chính. Khi triển khai thực tế, có thể gộp một số service để giảm độ phức tạp, nhưng vẫn giữ ranh giới chức năng như thiết kế. 


![image](https://cdn-mineru.openxlab.org.cn/result/2026-10-31/9f441dcc-ab95-444d-a0bd-90c555804308/7d1ea8b96a3efac18598d5cd92c1f77ab22e891fede458f064eb34623eff929e.jpg)


Giao tiếp: HTTPS cho vòng đời phiên; WSS Binary cho audio/frame realtime; JSON cho control và cảnh báo. 

Điều phối: AI Orchestrator xử lý yêu cầu người dùng; Safety Monitoring hoạt động độc lập. 

GPU: Scheduler ưu tiên Safety, hàng đợi giới hạn, bỏ frame cũ, hạn chế VLM. 

Khoảng cách: Ưu tiên ARCore Depth nếu thiết bị hỗ trợ; fallback Depth Anything V2; đánh giá độ tin cậy trước khi phát cảnh báo có số mét. 

Phản hồi: Kết quả thông thường qua Aggregator → TTS; cảnh báo khẩn qua Gateway → Mobile TTS cục bộ. 

Triển khai: Docker Compose, FastAPI, Redis, PostgreSQL cho nhật ký; chưa cần Kubernetes hoặc Kafka ở giai đoạn đầu. 

## Plan AI

1. Tìm hiểu về ASR 

⇒ Tìm data chuyên về ra lệnh đọc từ, miêu tả 

VD 

<table><tr><td>Nhóm</td><td>Số câu</td><td>Ví dụ</td></tr><tr><td>Đọc văn bản / OCR</td><td>45</td><td>&quot;Đọc giúp tôi chữ trên tờ giấy&quot;</td></tr><tr><td>Mô tả cảnh vật</td><td>50</td><td>&quot;Trước mặt tôi có những gì?&quot;</td></tr><tr><td>Hồi về vật cần</td><td>45</td><td>&quot;Phía trước có chương ngại vật không?&quot;</td></tr><tr><td>Nhận diện / định vị đối tượng</td><td>50</td><td>&quot;Chiếc ghế nằm ở phía nào?&quot;</td></tr><tr><td>Điều khiển ứng dụng</td><td>40</td><td>&quot;Dùng đọc&quot;, &quot;Nhắc lại&quot;</td></tr><tr><td>Hồi đáp tự nhiên</td><td>40</td><td>&quot;Có bao nhiều người trước mặt?&quot;</td></tr><tr><td>Câu phù định / ngoài phạm vi</td><td>30</td><td>&quot;Dùng đọc nữa&quot;, &quot;Hôm nay ăn gì?&quot;</td></tr><tr><td>Tổng</td><td>300</td><td></td></tr></table>

2. NLU 

3 nhiệm vụ chính cho NLU: 

a) Intent Classification – Phân loại ý định 

b) Entity Extraction – Trích xuất thông tin 

c) Slot Filling — Trích xuất tham số cho hành động 

=> Dùng PhoBert/ or v2: vì Chuyên về hiểu và phân tích văn bản tiếng Việt, phù hợp để phân loại ý định (Intent Classification), nhận diện thực thể (NER) và phân loại cảm xúc. ⇒ Đề xuất: PhoBERT-base fine-tuned cho Intent Classification, kết hợp Slot Extraction. 

<table><tr><td>Model</td><td>Tham số</td><td>Transformer layers</td><td>Hidden size</td><td>Attention heads</td></tr><tr><td>PhoBERT-base</td><td>135M</td><td>12</td><td>768</td><td>12</td></tr><tr><td>PhoBERT-large</td><td>370M</td><td>24</td><td>1024</td><td>16</td></tr><tr><td>PhoBERT-base-v2</td><td>135M</td><td>12</td><td>768</td><td>12</td></tr></table>

Nu trin khai cå hai nhim v, cn hai loi nhãn: 

<table><tr><td>Dataset</td><td>Đầu vào</td><td>Nhăn đầu ra</td></tr><tr><td>Intent Classification</td><td>Toàn bộ câu nói</td><td>READ_TEXT, DETECT_OBJECT, VISUAL_QUESTION ...</td></tr><tr><td>Slot Filling</td><td>Câu nói và vị trí từng token</td><td>B-OBJECT, I-OBJECT, B-DIRECTION ...</td></tr></table>

## 3. OCR

Các bài toán cần xử lý 

- Text Detection ⇒ Dataset A — Text Detection 

- Text Recognition ⇒ Dataset B — Text Recognition 

- Text Orientation 

- Text Rectification 

- Text Layout Analysis 

- Post-processing 

## Phạm vi:

Để bảo đảm tính khả thi trong giai đoạn nghiên cứu và phát triển, module OCR có những giới hạn sau: 

● Ngôn ngữ: Tập trung vào tiếng Việt và tiếng Anh; chưa tối ưu cho các hệ chữ khác. 

Chữ viết tay: Ưu tiên chữ viết tay rõ ràng; chữ viết tay quá khó đọc, chữ nối phức tạp hoặc chữ bị tẩy xóa không thuộc phạm vi bảo đảm. 

Chất lượng hình ảnh: Không bảo đảm nhận dạng chính xác khi ảnh quá mờ, mất nét, thiếu sáng nghiêm trọng hoặc văn bản bị che khuất. 

Chữ nghệ thuật: Chữ trang trí, chữ cách điệu mạnh hoặc chữ có hiệu ứng phức tạp có thể không được nhận dạng chính xác. 

Văn bản quá nhỏ: Phụ thuộc độ phân giải ảnh, khoảng cách camera và khả năng phát hiện của mô hình. 

● Ngữ nghĩa: OCR chỉ nhận dạng nội dung văn bản, không chịu trách nhiệm xác minh tính đúng đắn của thông tin hay giải thích nội dung chuyên môn. 

Thời gian thực: Hỗ trợ xử lý khung hình theo yêu cầu, không đặt mục tiêu chạy OCR liên tục trên mọi frame của camera. 

Đối với thông tin quan trọng như tên thuốc, liều lượng, hạn sử dụng hoặc biển cảnh báo, hệ thống cần thông báo khi kết quả không chắc chắn và không tự suy đoán phần chữ không đọc được. 

Đầu vào (Input) 

● Khung hình hoặc ảnh chụp từ Camera Manager. 

● Yêu cầu xử lý từ Input Router, ví dụ READ_TEXT. 

● Thông tin tùy chọn: vùng cần đọc, đối tượng mục tiêu, ngôn ngữ ưu tiên. 

<table><tr><td>Giai đoạn</td><td>Phạm vi</td></tr><tr><td>Giai đoạn 1 – Chức năng cốt lõi</td><td>Nhận dạng chữ in tiếng Việt/Anh, biển hiệu, nhãn sản phẩm, văn bản nhiều dòng; hỗ trợ phát hiện, nhận dạng, hiệu chỉnh hướng và đọc kết quả bằng TTS</td></tr><tr><td>Giai đoạn 2 – Mở rộng</td><td>Tôi ưu chữ viết tay, bổ cục tài liệu phức tạp, chữ nhỏ, ảnh trong điều kiện khó và tăng hiệu năng xử lý</td></tr></table>

⇒ Đề xuất chốt phạm vi cho đồ án: Module OCR hỗ trợ đọc chữ in tiếng Việt và tiếng Anh từ khung hình camera, bao gồm tài liệu, sách báo, biển báo, bảng hiệu và nhãn sản phẩm. Hệ thống hỗ trợ văn bản nhiều dòng, chữ nghiêng và bố cục cơ bản; chữ viết tay rõ nét được đưa vào phạm vi thử nghiệm mở rộng. Kết quả OCR được chuẩn hóa và chuyển sang TTS để phản hồi bằng giọng nói cho người dùng. 

Kế hoạch benchmark: 2 cấp 

OCR End-to-End: Kiểm thử các hệ thống OCR hoàn chỉnh, từ ảnh đầu vào đến văn bản đầu ra. 

OCR Component: Kiểm thử riêng Text Detection và Text Recognition để xác định thành phần nào cần cải thiện hoặc fine-tune. 

Cấp 1: End - to - end 

<table><tr><td>STT</td><td>Model / Framework</td><td>Phiên bản cần thử</td><td>Tiếng Việt</td><td>Chữ viết tay</td><td>U'u tiên</td></tr><tr><td>1</td><td>PaddleOCR</td><td>PP-OCRv3</td><td>Có</td><td>Cần đánh giá</td><td>Cao</td></tr><tr><td>2</td><td>PaddleOCR</td><td>PP-OCRv4</td><td>Có</td><td>Cần đánh giá</td><td>Rất cao</td></tr><tr><td>3</td><td>PaddleOCR</td><td>PP-OCRv5</td><td>Có cấu hình đa ngôn ngữ</td><td>Cần đánh giá</td><td>Rất cao</td></tr><tr><td>4</td><td>EasyOCR</td><td>Bản phát hành ổn định, dùng recognition model Gen2 nếu có cho ngôn ngữ đã chọn</td><td>Có</td><td>Cần đánh giá</td><td>Cao</td></tr><tr><td>5</td><td>Tesseract</td><td>5.x + vie/eng</td><td>Có</td><td>Hạn chế</td><td>Cao</td></tr><tr><td>6</td><td>VietOCR</td><td>VGG Transformer</td><td>Có</td><td>Cần đánh giá</td><td>Cao</td></tr><tr><td>9</td><td>TrOCR</td><td>Base Handwritten</td><td>Cần fine-tune tiếng Việt</td><td>Có</td><td>Cao cho nghiên cứu chữ viết tay</td></tr></table>


Lưu ý: VietOCR và TrOCR chủ yếu là mô hình Text Recognition, không phải pipeline phát hiện và nhận dạng hoàn chỉnh. Khi benchmark End-to-End, phải kết hợp chúng với Text Detection để bảo đảm công bằng. 



a) Nhóm Text Detection — Phát hiện vùng chữ


<table><tr><td>Model</td><td>Đặc điểm</td><td>Phù hợp</td></tr><tr><td>PP-OCRv6 Small Detection</td><td>PP-OCRv6_small_det</td><td>Mới, cân bằng tốc độ và độ chính xác</td></tr><tr><td>PP-OCRv6 Tiny Detection</td><td>PP-OCRv6_tiny_det</td><td>Siêu nhẹ, phù hợp thử nghiệm tốc độ</td></tr><tr><td>PP-OCRv5 Mobile Detection</td><td>PP-OCRv5_mobile_det</td><td>Nhẹ, có sẵn checkpoint</td></tr></table>


b) Nhóm Text Recognition — Nhận dạng nội dung chữ


<table><tr><td colspan="2">Model</td><td>Phiên bản / kiến trúc</td><td>Ưu điểm</td><td>Ưu tiên</td></tr><tr><td>PP-OCRv6 Recognition</td><td>Small</td><td>PP-OCRv6_small_rec</td><td>Mới, đa ngôn ngữ, cân bằng hiệu năng</td><td>Rất cao</td></tr><tr><td>PP-OCRv6 Recognition</td><td>Tiny</td><td>PP-OCRv6_tiny_rec</td><td>Rất nhẹ, tốc độ cao</td><td>Cao</td></tr><tr><td>PP-OCRv5 Recognition</td><td>Latin</td><td>latin_PP-OCRv5_mobile_rec</td><td>Có công bố hỗ trợ tiếng Việt</td><td>Rất cao</td></tr><tr><td colspan="2">VietOCR</td><td>VGG Transformer</td><td>Mô hình nhận dạng chữ tiếng Việt, phù hợp làm đối chứng</td><td>Trung bình</td></tr></table>


⇒ 3 cấp benchmark 


<table><tr><td>Cấp</td><td>Dữ liệu cần có</td><td>Đánh giá</td></tr><tr><td>Text Detection</td><td>Ảnh gốc + tọa độ vùng chữ (box/polygon)</td><td>Phát hiện đúng vị trí chữ hay không</td></tr><tr><td>Text Recognition</td><td>Ảnh đã cắt vùng chữ + văn bản chuẩn</td><td>Đọc đúng từng ký tự, từ, dấu tiếng Việt hay không</td></tr><tr><td>End-to-EndOCR</td><td>Ảnh gốc + vị trí chữ + nội dung chuẩn + thứ tự đọc</td><td>Từ ảnh camera đến văn bản cuối cùng có chính xác không</td></tr></table>


Đề xuất: các data sẽ dùng trong quá trình benchmark 


- VinText — Chữ trong cảnh đường phố Việt Nam phù hợp benchmark cho cả 3 phần 

MC-OCR 2021 — Hóa đơn Việt Nam ⇒ Dùng cho: Detection, Recognition, End-to-End, kiểm thử thông tin hóa đơn. 

Viet-Handwriting-OCR — Chữ viết tay tiếng Việt ⇒ Dùng cho: Text Recognition. Không trực tiếp là bộ benchmark Detection trên ảnh trang đầy đủ. 

UIT CORE Lab — SignboardText / ATTW / ViCalligraphy => Dùng cho: Mở rộng benchmark kiểu chữ lạ, chữ trang trí, biển hiệu. 

Dataset bổ sung cho hóa đơn, tài liệu và chữ chụp lệch: SROIE 2019/987 hóa đơn tiếng Anh, có box và text, chất lượng in không đồng đều, ICDAR 2015 /Ảnh chữ tự nhiên chụp bằng camera đeo người, nhiều góc lệch, VN Documents OCR v2/Khoảng 155 trang tài liệu tiếng Việt, có hóa đơn tổng hợp, biểu mẫu, hợp đồng, DocLayNet/Tài liệu nhiều cột, bảng, bố cục phức tạp 

## 4. VLM

a) Image captioning 

b) VQA: Hỏi đáp với ảnh 

Phạm vi 

<table><tr><td>STT</td><td>Chức năng</td><td>Mô tả</td><td>Ví dụ</td></tr><tr><td>1</td><td>Mô tả khung cảnh</td><td>Nhận biết và mô tả tổng quan môi trường</td><td>&quot;Phía trước là một con đường có nhiều xe máy.&quot;</td></tr><tr><td>2</td><td>Mô tả đối tượng</td><td>Mô tả đặc điểm, màu sắc, hình dạng của vật thể</td><td>&quot;Chiếc túi có màu đen.&quot;</td></tr><tr><td>3</td><td>Mô tả vị trí tương đối</td><td>Xác định đối tượng nằm bên trái, phải, phía trước hoặc gần đối tượng khác</td><td>&quot;Chiếc ghế nằm bên phải chiếc bàn.&quot;</td></tr><tr><td>4</td><td>Nhận biết hoạt động</td><td>Mô tả hoạt động quan sát được trong ảnh</td><td>&quot;Một người đang đi bộ qua đường.&quot;</td></tr><tr><td>5</td><td>Hồi đáp về vật thể</td><td>Trả lời câu hỏi về sự tồn tại, số lượng, màu sắc, đặc điểm</td><td>&quot;Có hai chiếc cốc trên bàn.&quot;</td></tr><tr><td>6</td><td>Hồi đáp về môi trường</td><td>Trả lời câu hỏi về bối cảnh, địa điểm hoặc tình huống</td><td>&quot;Đây có về là một của hàng.&quot;</td></tr><tr><td>7</td><td>Hồi đáp về vị trí</td><td>Trả lời đối tượng đang nằm ở đầu trong khung hình</td><td>&quot;Chai nước nằm bên trái quyền sách.&quot;</td></tr><tr><td>8</td><td>Hồi đáp kết hợp OCR</td><td>Sử dụng văn bản nhận dạng từ OCR để trả lời câu hỏi về chữ trong ảnh</td><td>&quot;Biển hiệu ghi &#x27;Nhà thuốc&#x27;.&quot;</td></tr></table>

Phạm vi riêng VQA 

<table><tr><td>Nhóm câu hỏi</td><td>Ví dụ</td><td>Uú tiên</td></tr><tr><td>Nhận diện đối tượng</td><td>&quot;Đây là vật gì?&quot;</td><td>Rất cao</td></tr><tr><td>Màu sắc, hình dạng</td><td>&quot;Chiếc áo này màu gì?&quot;</td><td>Cao</td></tr><tr><td>Số lượng</td><td>&quot;Có bao nhiều người phía trước?&quot;</td><td>Cao</td></tr><tr><td>Vị trí tương đối</td><td>&quot;Chai nước nằm ở dâu?&quot;</td><td>Rất cao</td></tr><tr><td>Hoạt động</td><td>&quot;Nguời phía trước đang làm gì?&quot;</td><td>Cao</td></tr><tr><td>Bối cảnh</td><td>&quot;Tôi đang ở trong phòng hay ngoài trời?&quot;</td><td>Cao</td></tr><tr><td>Văn bản trong ảnh</td><td>&quot;Trên bằng ghi gì?&quot;</td><td>Chuyển sang OCR hoặc kết hợp OCR</td></tr><tr><td>Câu hỏi không đủ dữ liệu</td><td>&quot;Nguời này tên gì?&quot;</td><td>Phải có khả năng từ chối suy đoán</td></tr></table>

## Yêu cầu:

Yêu cầu riêng cho người khiếm thị: Câu mô tả nên ngắn gọn, ưu tiên đối tượng quan trọng, vị trí tương đối và những thông tin có ích cho người dùng. Tránh mô tả quá dài hoặc suy đoán những chi tiết không nhìn rõ. 

## 4.1. Phm vi nghiên cu

S dng mt mô hình VLM pretrained có kh năng hiu hình nh và trà li bng ting Vit, tp trung vào hai bài toán: 

<table><tr><td>Bài toán</td><td>Chức năng</td><td>Đầu ra mong muốn</td></tr><tr><td>Image Captioning</td><td>Mô tả khung cảnh, đồ vật, hoạt động, vị trí tương đối</td><td>1–2 câu tiếng Việt ngắn gọn</td></tr><tr><td>Visual Question Answering (VQA)</td><td>Trả lời câu hỏi của người dùng dựa trên ảnh camera</td><td>Một câu trả lời trực tiếp, dễ hiểu</td></tr></table>

Yêu cu chung: Ngôn ng t nhiên, d nghe qua TTS; ưu tiên thông tin hu ích; không t suy đoán khi hình ành không đù rõ. 

## ⇒ Không nghiên cứu về AI ⇒ Nghiên cứu so sánh prompt/API mở Đề xuất ⇒

<table><tr><td>Nhà cung cấp</td><td>Hỗ trợ Image Captioning</td><td>Hỗ trợ VQA</td><td>Phù hợp</td></tr><tr><td>Google Gemini API</td><td>Có</td><td>Có</td><td>Rất đáng thử cho phần hồi tiếng Việt</td></tr><tr><td>OpenAI Vision API</td><td>Có</td><td>Có</td><td>Dễ xây dựng prompt và trả kết quả có cấu trúc</td></tr></table>

## 5. Detection

⇒ Khác với VLM, module Detection nên ưu tiên tốc độ, độ chính xác và khả năng hoạt động ổn định. Đề xuất nghiên cứu các mô hình nhỏ, có thể triển khai trực tiếp trên server Python. Các nhóm cần quan tâm: 

<table><tr><td>Nhánh</td><td>Mục tiêu</td><td>Ví dụ</td><td>Loại mô hình</td></tr><tr><td>P0 – Object Detection</td><td>Phát hiện vật thể có thể gây cần trở</td><td>Xe máy, người, cột điện, chậu cây,thùng rác, rào chấn</td><td>YOLO / RT-DETR</td></tr><tr><td>P1 – Hazard &amp; Walkable Area</td><td>Phát hiện nguy cơ trên mặt đất, bậcthềm, lối đi</td><td>Hố ga mở, ống, mép vía hè, càuthang, lối đi bị chấn</td><td>Detection +Segmentation</td></tr><tr><td>P2 – Spatial &amp; Dynamic Risk</td><td>Phát hiện nguy cơ tiềm ấn dưa trênkhông gian và chuyển động</td><td>Xe đang tiến tới, vật thể gần, nguycơ va chạm, vật treo ngang đầu</td><td>Tracking + Depth +Risk Scoring</td></tr></table>


Mức độ yêu cầu: 


Thứ tự nghiên cứu hợp lý: Benchmark mô hình cho từng nhánh → chọn mô hình tốt nhất của mỗi nhánh → thử nghiệm kết hợp → xây dựng dataset Việt Nam → fine-tune → benchmark lại trên dữ liệu Việt Nam độc lập. 

Điểm quan trọng là P2 không đơn thuần là một tập lớp vật thể khác của P0. Nó cần dữ liệu theo chuỗi thời gian hoặc thông tin khoảng cách, chứ không thể đánh giá đầy đủ bằng ảnh tĩnh. 

## Đề xuất model và data benchmark cho từng cấp độ

## 1. Data

<table><tr><td>Dataset</td><td>Sử dụng</td><td>Ghi chú</td></tr><tr><td>Sidewalk Obstacle Detection (SOD) ↗</td><td>P0</td><td>Vật cần trong môi trường đi bộ</td></tr><tr><td>Obstacles Avoidance Assistance ↗</td><td>P1</td><td>Hỗ, gờ nổi, cột, hàng rào</td></tr><tr><td>RDD2022 ↗</td><td>P1 bổ sung</td><td>Ố gà, hư hỏng mặt đường; góc nhìn xe nên không hoàn toàn tương đồng camera người đi bộ</td></tr><tr><td>MOT17 ↗</td><td>P2</td><td>Đánh giá Tracking người</td></tr><tr><td>BDD100K ↗</td><td>P2 bổ sung</td><td>Theo dõi phương tiện và người trong video giao thông</td></tr></table>


2. Bốn mô hình đối chứng: YOLO11n, YOLO11s, YOLO26n và YOLO26s. 



3. Giai đoạn 


Giai đoạn I – Benchmark trên dữ liệu công khai: Đánh giá bốn mô hình trong cùng điều kiện, lựa chọn mô hình phù hợp nhất. 

Giai đoạn II – Fine-tune trên dữ liệu Việt Nam: Thu thập và gán nhãn dữ liệu thực tế, huấn luyện tiếp mô hình được chọn, so sánh hiệu quả trước và sau khi fine-tune. 

Giai đoạn III - Benchmark lại 

## 6. TTS

Call API: cụ thể nghiên cứu prompt + API phù hợp 

Đề xuất 

<table><tr><td>Tiêu chí</td><td>FPT.AI TTS</td><td>Google Cloud TTS</td><td>OpenAI TTS</td></tr><tr><td>Tiếng Việt</td><td>Chuyên biệt, nhiều gióng vùng miền</td><td>Có gióng vi-VN</td><td>Hỗ trợ tiếng Việt</td></tr><tr><td>Điều chỉnh gióng</td><td>Chọn gióng, tốc độ</td><td>Chọn gióng, cấu hình phát âm tùy loại</td><td>Có khả năng điều khiển phong cách bằng instructions ở một số model</td></tr><tr><td>Tích hợp Python</td><td>REST API</td><td>SDK/API</td><td>SDK/API</td></tr><tr><td>Kết quả âm thanh</td><td>MP3/WAV</td><td>Các định dạng tùy API</td><td>MP3, WAV, PCM, Opus...</td></tr><tr><td>Điểm cần kiểm thử</td><td>Thời gian tạo âm thanh bất đồng bộ</td><td>Latency và chi phí</td><td>Phát âm tiếng Việt và tính phù hợp lâu dài của API</td></tr><tr><td>Vai trò đề xuất</td><td>Ứng viên chính về gióng Việt</td><td>Đối chứng</td><td>Đối chứng về khả năng điều khiển gióng</td></tr></table>