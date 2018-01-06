---
title: Mybatis+Spring 插件分页
date: 2018/01/05 11:46:25
tags: [深圳,Mybatis,Spring]
categories: Web
---

### 总体流程
最近研究了一下公司后台系统的分页实现机制，发现收获还是蛮多的，主要思想是使用Spring Aop 和Mybatis的插件拦截器，在特定sql执行之前进行拦截，然后判断数据库类型，加上相应分页语法，然后执行（以下以Mysql数据库作为示例）

#### _Talk is cheap,Show me the code_ ####

### mybatis-config.xml
首先是Mybatis的配置文件，mybatis-config.xml,应该是网上找的，都有详细注解，看看就好，平时这个配置基本没有改动，主要是在底部配置了 *PaginationInterceptor* 插件

<!-- more -->
```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE configuration PUBLIC "-//mybatis.org//DTD Config 3.0//EN" "http://mybatis.org/dtd/mybatis-3-config.dtd">
<configuration>

	<!-- 全局参数 -->
	<settings>
		<!-- 使全局的映射器启用或禁用缓存。 -->
		<setting name="cacheEnabled" value="true" />

		<!-- 全局启用或禁用延迟加载。当禁用时，所有关联对象都会即时加载。 -->
		<setting name="lazyLoadingEnabled" value="true" />

		<!-- 当启用时，有延迟加载属性的对象在被调用时将会完全加载任意属性。否则，每种属性将会按需要加载。 -->
		<setting name="aggressiveLazyLoading" value="true" />

		<!-- 是否允许单条sql 返回多个数据集 (取决于驱动的兼容性) default:true -->
		<setting name="multipleResultSetsEnabled" value="true" />

		<!-- 是否可以使用列的别名 (取决于驱动的兼容性) default:true -->
		<setting name="useColumnLabel" value="true" />

		<!-- 允许JDBC 生成主键。需要驱动器支持。如果设为了true，这个设置将强制使用被生成的主键，有一些驱动器不兼容不过仍然可以执行。 default:false -->
		<setting name="useGeneratedKeys" value="false" />

		<!-- 指定 MyBatis 如何自动映射 数据基表的列 NONE：不隐射 PARTIAL:部分 FULL:全部 -->
		<setting name="autoMappingBehavior" value="PARTIAL" />

		<!-- 这是默认的执行类型 （SIMPLE: 简单； REUSE: 执行器可能重复使用prepared statements语句；BATCH:
			执行器可以重复执行语句和批量更新） -->
		<setting name="defaultExecutorType" value="SIMPLE" />

		<!-- 使用驼峰命名法转换字段。 -->
		<setting name="mapUnderscoreToCamelCase" value="true" />

		<!-- 设置本地缓存范围 session:就会有数据的共享 statement:语句范围 (这样就不会有数据的共享 ) defalut:session -->
		<setting name="localCacheScope" value="SESSION" />

		<!-- 设置但JDBC类型为空时,某些驱动程序 要指定值,default:OTHER，插入空值时不需要指定类型 -->
		<setting name="jdbcTypeForNull" value="NULL" />
	</settings>

	<!-- 插件配置 -->
	<plugins>
		<plugin interceptor="com.mg.background.common.persistence.interceptor.PaginationInterceptor" />
	</plugins>

</configuration>

```
### 分页拦截器
分页拦截的功能主要由以下几个类实现    
（1）AbstractInterceptor 拦截器基础类    
（2）PaginationInterceptor 我们要使用的分页插件类，继承上面基础类    
（3）SQLHelper 主要是用来提前执行count语句，还有就是获取整个完整的分页语句    
（4）Dialect，MysqlDialect,主要用来数据库是否支持limit语句，然后封装完整limit语句  

#### AbstractInterceptor
```
public abstract class AbstractInterceptor implements Interceptor, Serializable {
	private static final long serialVersionUID = 7601006451417393141L;
	protected static final String PAGE = "pages";
	protected static final String DELEGATE = "delegate";
	protected static final String MAPPED_STATEMENT = "mappedStatement";
	protected Log log = LogFactory.getLog(this.getClass());
	protected Dialect DIALECT;

	@SuppressWarnings("unchecked")
	protected static Pages<Object> convertParameter(Object parameterObject, Pages<Object> page) {
		try {
			if (parameterObject instanceof Pages) {
				return (Pages<Object>) parameterObject;
			} else {
				return (Pages<Object>) Reflections.getFieldValue(parameterObject, PAGE);
			}
		} catch (Exception e) {
			return null;
		}
	}

	/**
	 * 设置属性，支持自定义方言类和制定数据库的方式
	 * <code>dialectClass</code>,自定义方言类。可以不配置这项
	 * <ode>dbms</ode> 数据库类型，插件支持的数据库
	 * <code>sqlPattern</code> 需要拦截的SQL ID
	 *
	 * @param p 属性
	 */
	protected void initProperties(Properties p) {
		Dialect dialect = null;
		String dbType = "mysql";//这里
		if ("db2".equals(dbType)) {
			dialect = new DB2Dialect();
		} else if ("derby".equals(dbType)) {
			dialect = new DerbyDialect();
		} else if ("h2".equals(dbType)) {
			dialect = new H2Dialect();
		} else if ("hsql".equals(dbType)) {
			dialect = new HSQLDialect();
		} else if ("mysql".equals(dbType)) {
			dialect = new MySQLDialect();
		} else if ("oracle".equals(dbType)) {
			dialect = new OracleDialect();
		} else if ("postgre".equals(dbType)) {
			dialect = new PostgreSQLDialect();
		} else if ("mssql".equals(dbType) || "sqlserver".equals(dbType)) {
			dialect = new SQLServer2005Dialect();
		} else if ("sybase".equals(dbType)) {
			dialect = new SybaseDialect();
		}
		if (dialect == null) {
			throw new RuntimeException("mybatis dialect error.");
		}
		DIALECT = dialect;
	}
}
```
主要是定义了 *convertParameter* 方法和使用 *initProperties* 配置方言类，类似一个简单工厂模式，方便切换数据库的时候，使用不同的分页语法。基本用不到，毕竟一个项目不可能随随便便更换数据库。

#### PaginationInterceptor
先看代码
```
@Intercepts({ @Signature(type = Executor.class, method = "query", args = { MappedStatement.class, Object.class, RowBounds.class, ResultHandler.class }) })
public class PaginationInterceptor extends AbstractInterceptor {
	private static final long serialVersionUID = 4989671349466153547L;

	@Override
	public Object intercept(Invocation invocation) throws Throwable {
		final MappedStatement mappedStatement = (MappedStatement) invocation.getArgs()[0];
		//        //拦截需要分页的SQL
		//        if (mappedStatement.getId().matches(_SQL_PATTERN)) {
		//        if (StringUtils.indexOfIgnoreCase(mappedStatement.getId(), _SQL_PATTERN) != -1) {
		Object parameter = invocation.getArgs()[1];
		BoundSql boundSql = mappedStatement.getBoundSql(parameter);
		Object parameterObject = boundSql.getParameterObject();
		//获取分页参数对象
		Pages<Object> pages = null;
		if (parameterObject != null) {
			pages = convertParameter(parameterObject, pages);
		}
		//如果设置了分页对象，则进行分页
		if (pages != null && pages.getPageSize() != -1) {
			if (StringUtils.isBlank(boundSql.getSql())) {
				return null;
			}
			String originalSql = boundSql.getSql().trim();
			//得到总记录数
			pages.setTotal(SQLHelper.getCount(originalSql, null, mappedStatement, parameterObject, boundSql, log));
			//分页查询 本地化对象 修改数据库注意修改实现
			String pageSql = SQLHelper.generatePageSql(originalSql, pages, DIALECT);
			//                if (log.isDebugEnabled()) {
			//                    log.debug("PAGE SQL:" + StringUtils.replace(pageSql, "\n", ""));
			//                }
			invocation.getArgs()[2] = new RowBounds(RowBounds.NO_ROW_OFFSET, RowBounds.NO_ROW_LIMIT);
			BoundSql newBoundSql = new BoundSql(mappedStatement.getConfiguration(), pageSql, boundSql.getParameterMappings(), boundSql.getParameterObject());
			//解决MyBatis 分页foreach 参数失效 start
			if (Reflections.getFieldValue(boundSql, "metaParameters") != null) {
				MetaObject mo = (MetaObject) Reflections.getFieldValue(boundSql, "metaParameters");
				Reflections.setFieldValue(newBoundSql, "metaParameters", mo);
			}
			//解决MyBatis 分页foreach 参数失效 end
			MappedStatement newMs = copyFromMappedStatement(mappedStatement, new BoundSqlSqlSource(newBoundSql));
			invocation.getArgs()[0] = newMs;
		}
		//        }
		return invocation.proceed();
	}

	@Override
	public Object plugin(Object target) {
		return Plugin.wrap(target, this);
	}

	@Override
	public void setProperties(Properties properties) {
		super.initProperties(properties);
	}

	private MappedStatement copyFromMappedStatement(MappedStatement ms, SqlSource newSqlSource) {
		MappedStatement.Builder builder = new MappedStatement.Builder(ms.getConfiguration(), ms.getId(), newSqlSource, ms.getSqlCommandType());
		builder.resource(ms.getResource());
		builder.fetchSize(ms.getFetchSize());
		builder.statementType(ms.getStatementType());
		builder.keyGenerator(ms.getKeyGenerator());
		if (ms.getKeyProperties() != null) {
			for (String keyProperty : ms.getKeyProperties()) {
				builder.keyProperty(keyProperty);
			}
		}
		builder.timeout(ms.getTimeout());
		builder.parameterMap(ms.getParameterMap());
		builder.resultMaps(ms.getResultMaps());
		builder.cache(ms.getCache());
		return builder.build();
	}

	public static class BoundSqlSqlSource implements SqlSource {
		BoundSql boundSql;

		public BoundSqlSqlSource(BoundSql boundSql) {
			this.boundSql = boundSql;
		}

		public BoundSql getBoundSql(Object parameterObject) {
			return boundSql;
		}
	}
}
```
在顶部使用了 *@Intercepts* 注解定义了需要拦截的sql语句，
> MyBatis 允许你在已映射语句执行过程中的某一点进行拦截调用。默认情况下，MyBatis 允许使用插件来拦截的方法调用包括：
Executor (update, query, flushStatements, commit, rollback, getTransaction, close, isClosed)    
ParameterHandler (getParameterObject, setParameters)    
ResultSetHandler (handleResultSets, handleOutputParameters)    
StatementHandler (prepare, parameterize, batch, update, query)    
总体概括为：    
拦截执行器的方法    
拦截参数的处理    
拦截结果集的处理    
拦截Sql语法构建的处理  

<div align=center>
![Mybatis四大接口](http://oyo2a85eo.bkt.clouddn.com//post/mybatis_page/Mybatis%E5%9B%9B%E5%A4%A7%E6%8E%A5%E5%8F%A3.jpeg)
</div>

>上图Mybatis框架的整个执行过程。Mybatis插件能够对则四大对象进行拦截，可以包含到了Mybatis一次会议的所有操作。可见Mybatis的的插件很强大。

>Executor是 Mybatis的内部执行器，它负责调用StatementHandler操作数据库，并把结果集通过 ResultSetHandler进行自动映射，另外，他还处理了二级缓存的操作。从这里可以看出，我们也是可以通过插件来实现自定义的二级缓存的。   
StatementHandler是Mybatis直接和数据库执行sql脚本的对象。另外它也实现了Mybatis的一级缓存。这里，我们可以使用插件来实现对一级缓存的操作(禁用等等)。    
ParameterHandler是Mybatis实现Sql入参设置的对象。插件可以改变我们Sql的参数默认设置。    
ResultSetHandler是Mybatis把ResultSet集合映射成POJO的接口对象。我们可以定义插件对Mybatis的结果集自动映射进行修改。

<div align=center>
![Mybatis四大接口](http://oyo2a85eo.bkt.clouddn.com//post/mybatis_batchInsert/sql.png)
</div>

运行的时候通过反射获取执行的方法以及参数，通过 *AbstractInterceptor* 中的 *convertParameter(Object parameterObject, Pages<Object> page)* 方法获取请求实体中的page对象（待会讲为什么实体中包含page对象），如果请求实体中包含page对象，即继续进行分页处理。

#### SQLHelper
```
/**
 * SQL工具类
 *
 * @author poplar.yfyang / thinkgem
 * @version 2013-8-28
 */
public class SQLHelper {
	/**
	 * 对SQL参数(?)设值,参考org.apache.ibatis.executor.parameter.DefaultParameterHandler
	 *
	 * @param ps              表示预编译的 SQL 语句的对象。
	 * @param mappedStatement MappedStatement
	 * @param boundSql        SQL
	 * @param parameterObject 参数对象
	 * @throws java.sql.SQLException 数据库异常
	 */
	@SuppressWarnings("unchecked")
	public static void setParameters(PreparedStatement ps, MappedStatement mappedStatement, BoundSql boundSql, Object parameterObject) throws SQLException {
		ErrorContext.instance().activity("setting parameters").object(mappedStatement.getParameterMap().getId());
		List<ParameterMapping> parameterMappings = boundSql.getParameterMappings();
		if (parameterMappings != null) {
			Configuration configuration = mappedStatement.getConfiguration();
			TypeHandlerRegistry typeHandlerRegistry = configuration.getTypeHandlerRegistry();
			MetaObject metaObject = parameterObject == null ? null : configuration.newMetaObject(parameterObject);
			for (int i = 0; i < parameterMappings.size(); i++) {
				ParameterMapping parameterMapping = parameterMappings.get(i);
				if (parameterMapping.getMode() != ParameterMode.OUT) {
					Object value;
					String propertyName = parameterMapping.getProperty();
					PropertyTokenizer prop = new PropertyTokenizer(propertyName);
					if (parameterObject == null) {
						value = null;
					} else if (typeHandlerRegistry.hasTypeHandler(parameterObject.getClass())) {
						value = parameterObject;
					} else if (boundSql.hasAdditionalParameter(propertyName)) {
						value = boundSql.getAdditionalParameter(propertyName);
					} else if (propertyName.startsWith(ForEachSqlNode.ITEM_PREFIX) && boundSql.hasAdditionalParameter(prop.getName())) {
						value = boundSql.getAdditionalParameter(prop.getName());
						if (value != null) {
							value = configuration.newMetaObject(value).getValue(propertyName.substring(prop.getName().length()));
						}
					} else {
						value = metaObject == null ? null : metaObject.getValue(propertyName);
					}
					@SuppressWarnings("rawtypes")
					TypeHandler typeHandler = parameterMapping.getTypeHandler();
					if (typeHandler == null) {
						throw new ExecutorException("There was no TypeHandler found for parameter " + propertyName + " of statement " + mappedStatement.getId());
					}
					typeHandler.setParameter(ps, i + 1, value, parameterMapping.getJdbcType());
				}
			}
		}
	}

	/**
	 * 查询总纪录数
	 *
	 * @param sql             SQL语句
	 * @param connection      数据库连接
	 * @param mappedStatement mapped
	 * @param parameterObject 参数
	 * @param boundSql        boundSql
	 * @return 总记录数
	 * @throws SQLException sql查询错误
	 */
	public static int getCount(final String sql, final Connection connection, final MappedStatement mappedStatement, final Object parameterObject, final BoundSql boundSql, Log log) throws SQLException {
		String dbName = "mysql"; //这里需要配置，目前只用mysql 暂时写死
		final String countSql;
		if ("oracle".equals(dbName)) {
			countSql = "select count(1) from (" + sql + ") tmp_count";
		} else {
			//countSql = "select count(1) from (" + change(sql) + ") tmp_count";
			countSql = "select count(1) " + removeSelect(removeOrders(sql));
		}
		Connection conn = connection;
		PreparedStatement ps = null;
		ResultSet rs = null;
		try {
			if (log.isDebugEnabled()) {
				log.debug("COUNT SQL: " + StringUtils.replaceEach(countSql, new String[] { "\n", "\t" }, new String[] { " ", " " }));
			}
			if (conn == null) {
				conn = mappedStatement.getConfiguration().getEnvironment().getDataSource().getConnection();
			}
			ps = conn.prepareStatement(countSql);
			BoundSql countBS = new BoundSql(mappedStatement.getConfiguration(), countSql, boundSql.getParameterMappings(), parameterObject);
			//解决MyBatis 分页foreach 参数失效 start
			if (Reflections.getFieldValue(boundSql, "metaParameters") != null) {
				MetaObject mo = (MetaObject) Reflections.getFieldValue(boundSql, "metaParameters");
				Reflections.setFieldValue(countBS, "metaParameters", mo);
			}
			//解决MyBatis 分页foreach 参数失效 end
			SQLHelper.setParameters(ps, mappedStatement, countBS, parameterObject);
			rs = ps.executeQuery();
			int count = 0;
			if (rs.next()) {
				count = rs.getInt(1);
			}
			return count;
		} finally {
			if (rs != null) {
				rs.close();
			}
			if (ps != null) {
				ps.close();
			}
			if (conn != null) {
				conn.close();
			}
		}
	}

	/**
	 * 根据数据库方言，生成特定的分页sql
	 *
	 * @param sql     Mapper中的Sql语句
	 * @param page    分页对象
	 * @param dialect 方言类型
	 * @return 分页SQL
	 */
	public static String generatePageSql(String sql, Pages<Object> page, Dialect dialect) {
		if (dialect.supportsLimit()) {
			return dialect.getLimitString(sql, page.getFirstResult(), page.getMaxResults());
		} else {
			return sql;
		}
	}

	/**
	 * 去除qlString的select子句。
	 *
	 * @param hql
	 * @return
	 */
	@SuppressWarnings("unused")
	private static String removeSelect(String qlString) {
		int beginPos = qlString.toLowerCase().indexOf("from");
		return qlString.substring(beginPos);
	}

	/**
	 * 去除hql的orderBy子句。
	 *
	 * @param hql
	 * @return
	 */
	private static String removeOrders(String qlString) {
		Pattern p = Pattern.compile("order\\s*by[\\w|\\W|\\s|\\S]*", Pattern.CASE_INSENSITIVE);
		Matcher m = p.matcher(qlString);
		StringBuffer sb = new StringBuffer();
		while (m.find()) {
			m.appendReplacement(sb, "");
		}
		m.appendTail(sb);
		return sb.toString();
	}
}
```

*SQLHelper* 是一个对执行sql进行预处理的第三方工具类， *PaginationInterceptor.java* 中调用的主要是 *SQLHelper* 中的 *getCount()*和 *generatePageSql()* 方法，获取查询总条数和根据 *dialect* 类的不同，来拼接不同的数据库的 *limit* 语句。

#### Dialect方言类

*PaginationInterceptor* 通过父类 *AbstractInterceptor* 中工厂方法获取到预先设定的 *MySQLDialect*,针对Mysql数据库，实现分页查询语句的拼接。

```
/**
 * Mysql方言的实现
 */
public class MySQLDialect implements Dialect {
	@Override
	public String getLimitString(String sql, int offset, int limit) {
		return getLimitString(sql, offset, Integer.toString(offset), Integer.toString(limit));
	}

	public boolean supportsLimit() {
		return true;
	}

	/**
	 * 将sql变成分页sql语句,提供将offset及limit使用占位符号(placeholder)替换.
	 * <pre>
	 * 如mysql
	 * dialect.getLimitString("select * from user", 12, ":offset",0,":limit") 将返回
	 * select * from user limit :offset,:limit
	 * </pre>
	 *
	 * @param sql               实际SQL语句
	 * @param offset            分页开始纪录条数
	 * @param offsetPlaceholder 分页开始纪录条数－占位符号
	 * @param limitPlaceholder  分页纪录条数占位符号
	 * @return 包含占位符的分页sql
	 */
	public String getLimitString(String sql, int offset, String offsetPlaceholder, String limitPlaceholder) {
		StringBuilder stringBuilder = new StringBuilder(sql);
		stringBuilder.append(" limit ");
		if (offset > 0) {
			stringBuilder.append(offsetPlaceholder).append(",").append(limitPlaceholder);
		} else {
			stringBuilder.append(limitPlaceholder);
		}
		return stringBuilder.toString();
	}
}
```

PS：实体中为什么包含Page对象，因为所有实体继承一个叫 *BaseEntity* 的父类，其中包含一些通用方法和属性，比如id，createTime，createBy等，还包含page对象，这样请求的时候就可以把page对象封装在请求体中，非常方便。

#### page
最后贴上page类

```
/**
 * 分页类
 *
 */
public class Pages<T> {
	private int pageNo = 1; // 当前页码
	private int pageSize = 10; // 页面大小，设置为“-1”表示不进行分页（分页无效）
	private long total;// 总记录数，设置为“-1”表示不查询总数
	private List<T> rows = new ArrayList<T>();

	public Pages() {
		this.pageSize = -1;
	}

	/**
	 * 构造方法
	 *
	 * @param pageNo   当前页码
	 * @param pageSize 分页大小
	 */
	public Pages(int pageNo, int pageSize) {
		this(pageNo, pageSize, 0);
	}

	public Pages(HttpServletRequest request, HttpServletResponse response) {
		this(request, response, -2);
	}

	public Pages(HttpServletRequest request, HttpServletResponse response, int defaultPageSize) {
		String page = request.getParameter("page");
		this.setPageNo(Integer.parseInt(page));
		String size = request.getParameter("rows");
		this.setPageSize(Integer.parseInt(size));
	}

	/**
	 * 构造方法
	 *
	 * @param pageNo   当前页码
	 * @param pageSize 分页大小
	 * @param count    数据条数
	 */
	public Pages(int pageNo, int pageSize, long count) {
		this(pageNo, pageSize, count, new ArrayList<T>());
	}

	/**
	 * 构造方法
	 *
	 * @param pageNo   当前页码
	 * @param pageSize 分页大小
	 * @param count    数据条数
	 * @param list     本页数据对象列表
	 */
	public Pages(int pageNo, int pageSize, long count, List<T> list) {
		this.setTotal(count);
		this.setPageNo(pageNo);
		this.pageSize = pageSize;
		this.rows = list;
	}

	/**
	 * 获取设置总数
	 *
	 * @return
	 */
	public long getTotal() {
		return total;
	}

	/**
	 * 设置数据总数
	 *
	 * @param count
	 */
	public void setTotal(long count) {
		this.total = count;
		if (pageSize >= count) {
			pageNo = 1;
		}
	}

	/**
	 * 获取当前页码
	 *
	 * @return
	 */
	public int getPageNo() {
		return pageNo;
	}

	/**
	 * 设置当前页码
	 *
	 * @param pageNo
	 */
	public void setPageNo(int pageNo) {
		this.pageNo = pageNo;
	}

	/**
	 * 获取页面大小
	 *
	 * @return
	 */
	public int getPageSize() {
		return pageSize;
	}

	/**
	 * 设置页面大小（最大500）
	 *
	 * @param pageSize
	 */
	public void setPageSize(int pageSize) {
		this.pageSize = pageSize <= 0 ? 10 : pageSize;// > 500 ? 500 : pageSize;
	}

	/**
	 * 获取本页数据对象列表
	 *
	 * @return List<T>
	 */
	public List<T> getRows() {
		return rows;
	}

	/**
	 * 设置本页数据对象列表
	 *
	 * @param list
	 */
	public Pages<T> setRows(List<T> list) {
		this.rows = list;
		return this;
	}

	/**
	 * 分页是否有效
	 *
	 * @return this.pageSize==-1
	 */
	public boolean isDisabled() {
		return this.pageSize == -1;
	}

	/**
	 * 是否进行总数统计
	 *
	 * @return this.count==-1
	 */
	public boolean isNotCount() {
		return this.total == -1;
	}

	/**
	 * 获取 Hibernate FirstResult
	 */
	public int getFirstResult() {
		int firstResult = (getPageNo() - 1) * getPageSize();
		if (firstResult >= getTotal()) {
			firstResult = 0;
		}
		return firstResult;
	}

	/**
	 * 获取 Hibernate MaxResults
	 */
	public int getMaxResults() {
		return getPageSize();
	}
}
```
### 结尾
#### _参考文章_ 	
CDNS：[mybatis常用分页插件，快速分页处理](http://blog.csdn.net/u014001866/article/details/52806930)
简书：[Mybatis插件原理 作者：曹金桂](https://www.jianshu.com/p/7c7b8c2c985d)
