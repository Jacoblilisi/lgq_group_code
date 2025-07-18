<template>
  <div class="addArticle">
    <el-form ref="article" :inline="true" :model="article" label-width="80px">
      <el-form-item label="文章标题">
        <el-input class="title" v-model="article.title" />
      </el-form-item>
      <el-form-item label="标签">
        <el-autocomplete
          class="inline-input"
          v-model="article.sort"
          :fetch-suggestions="querySearch"
          placeholder="请输入内容"
          @select="handleSelect"
        />
      </el-form-item>
      <el-form-item label="是否置顶">
        <el-switch v-model="article.top" />
      </el-form-item>

      <el-form-item>
        <el-button class="subBtn" type="primary" @click="submitArticle">发布</el-button>
      </el-form-item>
      <br />

      <el-form-item label="缩略图上传" label-width="95px">
        <el-upload
          class="avatar-uploader"
          :action="this.$path + '/editor/uploadImg'"
          :show-file-list="false"
          :on-success="handlethumbnailSuccess"
          :before-upload="beforethumbnailUpload"
        >
          <img v-if="article.thumbnail" :src="article.thumbnail" class="avatar" />
          <i v-else class="el-icon-plus avatar-uploader-icon"></i>
        </el-upload>
      </el-form-item>

      <el-form-item label="banner图上传" label-width="110px">
        <el-upload
          class="avatar-uploader"
          action="/api/editor/uploadImg"
          :show-file-list="false"
          :on-success="handleBannerSuccess"
          :before-upload="beforeBannerUpload"
        >
          <img v-if="article.banner" :src="article.banner" class="avatar" />
          <i v-else class="el-icon-plus avatar-uploader-icon"></i>
        </el-upload>
      </el-form-item>

      <el-form-item label="视频上传" label-width="95px">
        <el-upload
          class="avatar-uploader"
          :action="this.$path + '/editor/uploadVideo'"
          :show-file-list="false"
          :on-success="handleVideoSuccess"
          :before-upload="beforeVideoUpload"
          accept="video/*"
        >
          <video v-if="article.video" :src="article.video" class="video-preview" controls></video>
          <i v-else class="el-icon-plus avatar-uploader-icon"></i>
        </el-upload>
      </el-form-item>

      <!-- ✅ 考试文件上传 -->
      <el-form-item label="考试文件上传" label-width="110px">
        <el-upload
          class="exam-uploader"
          :action="this.$path + '/editor/uploadExamFile'"
          :show-file-list="false"
          :on-success="handleExamFileSuccess"
          :before-upload="beforeExamFileUpload"
          :limit="1"
          accept=".pdf,.doc,.docx,.xls,.xlsx,.zip,.rar,.7z"
        >
          <el-button type="primary" icon="el-icon-upload2">
            {{ article.examFile ? '重新上传考试文件' : '上传考试文件' }}
          </el-button>
        </el-upload>

        <div v-if="article.examFile" class="exam-file-info">
          <el-link :href="article.examFile" target="_blank" type="primary">
            点击查看已上传文件
          </el-link>
          <el-button
            type="text"
            icon="el-icon-delete"
            @click="removeExamFile"
            style="color: red; margin-left: 10px;"
          >
            删除
          </el-button>
        </div>
        <div class="el-upload__tip">支持 PDF、Word、Excel、压缩包，最大20MB</div>
      </el-form-item>
    </el-form>

    <div ref="editor" style="text-align:left"></div>
  </div>
</template>

<script>
import E from "wangeditor";

export default {
  name: "addArticle",
  data() {
    return {
      article: {
        title: "文章测试-标题",
        sort: "",
        top: true,
        content_html: "",
        thumbnail: "",
        banner: "",
        video: "",
        examFile: "" // ✅ 新增
      },
      initData: "",
      restaurants: []
    };
  },
  methods: {
    // ✅ 缩略图
    handlethumbnailSuccess(res, file) {
      this.article.thumbnail = res.data[0];
    },
    beforethumbnailUpload(file) {
      const isJPG = file.type === "image/jpeg";
      const isPNG = file.type === "image/png";
      const isLt2M = file.size / 1024 / 1024 < 2;
      if (!(isJPG || isPNG)) {
        this.$message.error("上传文章缩略图只能是 JPG/PNG 格式!");
      }
      if (!isLt2M) {
        this.$message.error("上传文章缩略图大小不能超过 2MB!");
      }
      return isLt2M && (isJPG || isPNG);
    },

    // ✅ banner
    handleBannerSuccess(res, file) {
      this.article.banner = res.data[0];
    },
    beforeBannerUpload(file) {
      const isJPG = file.type === "image/jpeg";
      const isPNG = file.type === "image/png";
      const isLt5M = file.size / 1024 / 1024 < 5;
      if (!(isJPG || isPNG)) {
        this.$message.error("上传banner只能是 JPG/PNG 格式!");
      }
      if (!isLt5M) {
        this.$message.error("上传banner图片大小不能超过 5MB!");
      }
      return isLt5M && (isJPG || isPNG);
    },

    // ✅ 视频上传
    handleVideoSuccess(res, file) {
      this.article.video = res.data[0];
    },
    beforeVideoUpload(file) {
      const isVideo = file.type.startsWith("video/");
      const isLt50M = file.size / 1024 / 1024 < 50;
      if (!isVideo) {
        this.$message.error("只能上传视频文件!");
      }
      if (!isLt50M) {
        this.$message.error("上传视频大小不能超过 50MB!");
      }
      return isVideo && isLt50M;
    },

    // ✅ 考试文件上传
    handleExamFileSuccess(res, file) {
      if (res.data && res.data[0]) {
        this.article.examFile = res.data[0];
        this.$message.success("考试文件上传成功");
      } else {
        this.$message.error("上传失败，请重试");
      }
    },
    beforeExamFileUpload(file) {
      const isAllowed =
        file.type.includes("pdf") ||
        file.type.includes("msword") ||
        file.type.includes("officedocument") ||
        file.type.includes("zip") ||
        /\.(rar|7z)$/i.test(file.name);
      const isLt20M = file.size / 1024 / 1024 < 20;

      if (!isAllowed) {
        this.$message.error("仅支持 PDF、Word、Excel 或压缩包格式");
      }
      if (!isLt20M) {
        this.$message.error("上传文件不能超过 20MB");
      }

      return isAllowed && isLt20M;
    },
    removeExamFile() {
      this.article.examFile = "";
      this.$message.success("考试文件已移除");
    },

    // 其他功能
    querySearch(queryString, cb) {
      var results = queryString
        ? this.restaurants.filter(this.createFilter(queryString))
        : this.restaurants;
      cb(results);
    },
    createFilter(queryString) {
      return restaurant =>
        restaurant.value.toLowerCase().indexOf(queryString.toLowerCase()) === 0;
    },
    loadAll() {
      return [
        { value: "vue" },
        { value: "node.js" }
      ];
    },
    handleSelect(item) {
      console.log(item);
    },
    submitArticle() {
      this.$request
        .fetchAddArticle(this.article)
        .then(response => {
          this.$restBack(response.data);
        })
        .catch(error => {
          console.log(error);
        });
    }
  },
  mounted() {
    let that = this;
    this.restaurants = this.loadAll();
    var editor = new E(this.$refs.editor);
    editor.customConfig.onchange = html => {
      that.article.content_html = html;
    };
    editor.customConfig.uploadImgServer = "/router/editor/uploadImg";
    editor.customConfig.debug = true;
    editor.create();

    let id = this.$route.query.articleId;
    if (!id) return false;
    this.$request
      .fetchGetArticle({ id })
      .then(response => {
        that.article = response.data;
        editor.txt.html(response.data.content_html);
      })
      .catch(error => {
        console.log(error);
      });
  }
};
</script>

<style scoped>
.title {
  width: 1000px;
}
.subBtn {
  width: 100px;
  margin: 0 auto;
}
.avatar-uploader .el-upload {
  border: 1px dashed #d9d9d9;
  border-radius: 6px;
  cursor: pointer;
  position: relative;
  overflow: hidden;
}
.avatar-uploader .el-upload:hover {
  border-color: #409EFF;
}
.avatar-uploader-icon {
  font-size: 28px;
  color: #8c939d;
  width: 178px;
  height: 178px;
  line-height: 178px;
  text-align: center;
}
.avatar {
  width: 178px;
  height: 178px;
  display: block;
}
.video-preview {
  width: 300px;
  height: 180px;
  object-fit: cover;
  border: 1px solid #ccc;
}
.exam-file-info {
  margin-top: 10px;
  font-size: 14px;
}
</style>

<style>
.el-autocomplete-suggestion {
  z-index: 10010 !important;
}
.w-e-text-container {
  height: 600px !important;
}
</style>
