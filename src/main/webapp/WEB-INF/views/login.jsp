<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="Donor Login"/>
    <jsp:param name="nav" value="login"/>
</jsp:include>

<div class="container">
    <div class="card form-card narrow">
        <h2>Donor login</h2>
        <p class="muted">New here? <a href="${ctx}/register">Register as a donor</a>.</p>
        <c:if test="${not empty error}">
            <div class="alert alert-error"><c:out value="${error}"/></div>
        </c:if>
        <form action="${ctx}/login" method="post">
            <input type="hidden" name="csrf" value="${sessionScope.csrf}">
            <div class="field" style="margin-bottom:14px">
                <label for="email">Email</label>
                <input type="email" id="email" name="email" required value="<c:out value='${param.email}'/>">
            </div>
            <div class="field" style="margin-bottom:18px">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required>
            </div>
            <button type="submit" class="btn" style="width:100%">Log in</button>
        </form>
    </div>
</div>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
