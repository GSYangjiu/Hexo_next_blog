{% if not (theme.duoshuo and theme.duoshuo.shortname)
   and not theme.duoshuo_shortname
   and not theme.disqus_shortname
   and not theme.hypercomments_id
   and not theme.gentie_productKey %}
   {% if theme.laibili_uid %}
     {% set uid = theme.laibili_uid %}
   {% endif %}
  {% if page.comments %}
       <!-- 来必力City版安装代码 -->
       <script type="text/javascript">
          (function(d, s) {
              var j, e = d.getElementsByTagName(s)[0];

              if (typeof LivereTower === 'function') { return; }

              j = d.createElement(s);
              j.src = 'https://cdn-city.livere.com/js/embed.dist.js';
              j.async = true;

              e.parentNode.insertBefore(j, e);
          })(document, 'script');
       </script>
       <noscript>为正常使用来必力评论功能请激活JavaScript</noscript>
       <!-- City版安装代码已完成 -->
   {% endif %}
 {% endif %}
