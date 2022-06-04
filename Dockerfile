FROM nvcr.io/nvidia/pytorch:22.04-py3

ARG PROXY_URL

RUN apt-get update \
    # SSHサーバをインストール
    && apt-get install -q -y ssh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # SSHサーバが動作するために必要なsockファイルが配置されるディレクトリを用意
    && mkdir /var/run/sshd \
    # rootでログインできるようにするため、パスワードを設定(ただしこのパスワードは使いません)
    && echo 'root:password' | chpasswd \
    # パスワードでのログインをできないようにする
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config # 

# SSHで使用する公開鍵をここでコピーする
WORKDIR /
COPY id_rsa.pub /root/.ssh/authorized_keys
# SSHポートを公開する(Docker Composeで別のポートにバインドするので22番ポートのまま)
EXPOSE 22

# その他開発に必要なプログラムのインストールなど
RUN apt-get update

# conda仮想環境作成
RUN conda create -n myenv python=3.9
# 仮想環境の activate 
ENV CONDA_DEFAULT_ENV myenv
# コンテナログイン用設定
RUN echo "conda activate myenv" >> ~/.bashrc
RUN echo "PATH=${PATH}:/opt/conda/envs/myenv/bin" >> ~/.bashrc

# ライブラリのインストール
RUN pip install pyanom

#.bash_profileを作成し、.bashrcを読み込む（シェルスクリプト）
RUN echo "if [ -f ~/.bashrc ]; then  . ~/.bashrc;  fi" >> ~/.bash_profile
# 環境変数の書き込み
RUN echo "HTTP_PROXY=${PROXY_URL}" >> ~/.bashrc
RUN echo "http_proxy=${PROXY_URL}" >> ~/.bashrc
RUN echo "HTTPS_PROXY=${PROXY_URL}" >> ~/.bashrc
RUN echo "https_proxy=${PROXY_URL}" >> ~/.bashrc

CMD ["/usr/sbin/sshd", "-D"]