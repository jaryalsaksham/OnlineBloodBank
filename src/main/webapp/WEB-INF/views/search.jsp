<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="Find Donors"/>
    <jsp:param name="nav" value="search"/>
</jsp:include>

<div class="container">
    <div class="page-head">
        <h1>Find blood donors</h1>
        <p class="muted">Search registered donors by blood group and city. To protect donors' privacy, phone numbers are
            visible only to the blood bank. Need blood urgently? <a href="${ctx}/request-blood">Raise a request</a>
            and the blood bank will help you.</p>
    </div>

    <form action="${ctx}/search" method="get" class="card filter-bar">
        <input type="hidden" name="searched" value="1">
        <div class="field">
            <label for="bloodGroup">Blood group</label>
            <select id="bloodGroup" name="bloodGroup">
                <option value="">Any</option>
                <c:forEach var="g" items="${bloodGroups}">
                    <option value="${g}" ${param.bloodGroup == g ? 'selected' : ''}>${g}</option>
                </c:forEach>
            </select>
        </div>
        <div class="field">
            <label for="city">City</label>
            <input type="text" id="city" name="city" maxlength="60" placeholder="e.g. Ludhiana"
                   value="<c:out value='${param.city}'/>">
        </div>
        <label class="check" style="padding-bottom:10px">
            <input type="checkbox" name="eligible" value="1" ${not empty param.eligible ? 'checked' : ''}>
            <span>Only donors who can donate now</span>
        </label>
        <button type="submit" class="btn">Search</button>
    </form>

    <c:if test="${not empty param.searched}">
        <p class="muted"><strong><c:out value="${results.size()}"/></strong> donor(s) found.</p>
        <div class="table-wrap">
            <table>
                <thead>
                <tr><th>Name</th><th>Group</th><th>City</th><th>Age</th><th>Availability</th><th>Contact</th></tr>
                </thead>
                <tbody>
                <c:forEach var="d" items="${results}">
                    <tr>
                        <td><c:out value="${d.fullName}"/></td>
                        <td><span class="badge badge-group"><c:out value="${d.bloodGroup}"/></span></td>
                        <td><c:out value="${d.city}"/></td>
                        <td><c:out value="${d.age}"/></td>
                        <td>
                            <c:choose>
                                <c:when test="${d.eligible}"><span class="badge badge-eligible">Can donate now</span></c:when>
                                <c:otherwise><span class="badge badge-wait">Not available yet</span></c:otherwise>
                            </c:choose>
                        </td>
                        <td>
                            <c:choose>
                                <c:when test="${not empty sessionScope.admin}"><c:out value="${d.phone}"/></c:when>
                                <c:otherwise><span class="muted"><c:out value="${d.maskedPhone}"/></span></c:otherwise>
                            </c:choose>
                        </td>
                    </tr>
                </c:forEach>
                <c:if test="${empty results}">
                    <tr><td colspan="6" class="empty-row">No donors match your search.</td></tr>
                </c:if>
                </tbody>
            </table>
        </div>
    </c:if>
</div>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
