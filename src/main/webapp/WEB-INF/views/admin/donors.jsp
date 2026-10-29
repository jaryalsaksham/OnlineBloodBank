<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="Manage Donors"/>
    <jsp:param name="nav" value="admin"/>
</jsp:include>
<jsp:include page="/WEB-INF/views/common/adminnav.jsp"><jsp:param name="tab" value="donors"/></jsp:include>

<div class="container">
    <div class="page-head">
        <h1>Donors</h1>
    </div>

    <form action="${ctx}/admin/donors" method="get" class="card filter-bar">
        <div class="field">
            <label for="bloodGroup">Blood group</label>
            <select id="bloodGroup" name="bloodGroup">
                <option value="">All</option>
                <c:forEach var="g" items="${bloodGroups}">
                    <option value="${g}" ${filterGroup == g ? 'selected' : ''}>${g}</option>
                </c:forEach>
            </select>
        </div>
        <button type="submit" class="btn">Filter</button>
    </form>

    <div class="table-wrap">
        <table>
            <thead>
            <tr><th>Name</th><th>Group</th><th>Contact</th><th>City</th><th>Age</th><th>Last donation</th><th>Status</th><th>Actions</th></tr>
            </thead>
            <tbody>
            <c:forEach var="d" items="${donors}">
                <tr>
                    <td><c:out value="${d.fullName}"/><br><span class="muted small">Joined <fmt:formatDate value="${d.registeredOn}" pattern="dd MMM yyyy"/></span></td>
                    <td><span class="badge badge-group"><c:out value="${d.bloodGroup}"/></span></td>
                    <td><c:out value="${d.phone}"/><br><span class="muted small"><c:out value="${d.email}"/></span></td>
                    <td><c:out value="${d.city}"/></td>
                    <td><c:out value="${d.age}"/></td>
                    <td>
                        <c:choose>
                            <c:when test="${empty d.lastDonationDate}"><span class="muted">Never</span></c:when>
                            <c:otherwise><fmt:formatDate value="${d.lastDonationDate}" pattern="dd MMM yyyy"/></c:otherwise>
                        </c:choose>
                    </td>
                    <td>
                        <c:choose>
                            <c:when test="${not d.active}"><span class="badge badge-inactive">Deactivated</span></c:when>
                            <c:when test="${d.eligible}"><span class="badge badge-eligible">Eligible</span></c:when>
                            <c:otherwise><span class="badge badge-wait">Waiting</span></c:otherwise>
                        </c:choose>
                    </td>
                    <td class="actions">
                        <form action="${ctx}/admin/donors" method="post" class="inline-form">
                            <input type="hidden" name="csrf" value="${sessionScope.csrf}">
                            <input type="hidden" name="id" value="${d.id}">
                            <button type="submit" name="action" value="toggle" class="btn btn-sm btn-outline">
                                ${d.active ? 'Deactivate' : 'Activate'}</button>
                            <button type="submit" name="action" value="delete" class="btn btn-sm"
                                    onclick="return confirm('Delete this donor and all of their donation history? This cannot be undone.');">Delete</button>
                        </form>
                    </td>
                </tr>
            </c:forEach>
            <c:if test="${empty donors}">
                <tr><td colspan="8" class="empty-row">No donors found.</td></tr>
            </c:if>
            </tbody>
        </table>
    </div>
</div>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
