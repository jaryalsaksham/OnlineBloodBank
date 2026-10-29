<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="Blood Requests"/>
    <jsp:param name="nav" value="admin"/>
</jsp:include>
<jsp:include page="/WEB-INF/views/common/adminnav.jsp"><jsp:param name="tab" value="requests"/></jsp:include>

<div class="container">
    <div class="page-head">
        <h1>Blood requests</h1>
        <p class="muted">Approving a request reserves the units and deducts them from stock. Mark it fulfilled once the blood is handed over.</p>
    </div>

    <form action="${ctx}/admin/requests" method="get" class="card filter-bar">
        <div class="field">
            <label for="status">Status</label>
            <select id="status" name="status">
                <option value="">All</option>
                <option value="PENDING" ${filterStatus == 'PENDING' ? 'selected' : ''}>Pending</option>
                <option value="APPROVED" ${filterStatus == 'APPROVED' ? 'selected' : ''}>Approved</option>
                <option value="FULFILLED" ${filterStatus == 'FULFILLED' ? 'selected' : ''}>Fulfilled</option>
                <option value="REJECTED" ${filterStatus == 'REJECTED' ? 'selected' : ''}>Rejected</option>
            </select>
        </div>
        <button type="submit" class="btn">Filter</button>
    </form>

    <div class="table-wrap">
        <table>
            <thead>
            <tr><th>ID</th><th>Requester</th><th>Hospital</th><th>Blood</th><th>Urgency</th><th>Status</th><th>Action</th></tr>
            </thead>
            <tbody>
            <c:forEach var="r" items="${requests}">
                <tr>
                    <td>#<c:out value="${r.id}"/><br><span class="muted small"><fmt:formatDate value="${r.requestedOn}" pattern="dd MMM, HH:mm"/></span></td>
                    <td><c:out value="${r.requesterName}"/><br><span class="muted small"><c:out value="${r.phone}"/></span>
                        <c:if test="${not empty r.email}"><br><span class="muted small"><c:out value="${r.email}"/></span></c:if></td>
                    <td><c:out value="${r.hospital}"/>, <c:out value="${r.city}"/>
                        <c:if test="${not empty r.reason}"><br><span class="muted small"><c:out value="${r.reason}"/></span></c:if></td>
                    <td><span class="badge badge-group"><c:out value="${r.bloodGroup}"/></span> &times; <c:out value="${r.unitsRequired}"/></td>
                    <td><span class="badge badge-${r.urgency}"><c:out value="${r.urgency}"/></span></td>
                    <td><span class="badge badge-${r.status}"><c:out value="${r.status}"/></span>
                        <c:if test="${not empty r.adminRemarks}"><br><span class="muted small"><c:out value="${r.adminRemarks}"/></span></c:if></td>
                    <td>
                        <c:if test="${r.status == 'PENDING' or r.status == 'APPROVED'}">
                            <form action="${ctx}/admin/requests" method="post" class="inline-form">
                                <input type="hidden" name="csrf" value="${sessionScope.csrf}">
                                <input type="hidden" name="id" value="${r.id}">
                                <input type="hidden" name="status" value="${filterStatus}">
                                <input type="text" name="remarks" placeholder="Remarks (optional)" maxlength="255" style="width:150px">
                                <c:if test="${r.status == 'PENDING'}">
                                    <button type="submit" name="action" value="approve" class="btn btn-sm btn-green">Approve</button>
                                    <button type="submit" name="action" value="reject" class="btn btn-sm"
                                            onclick="return confirm('Reject request #${r.id}?');">Reject</button>
                                </c:if>
                                <c:if test="${r.status == 'APPROVED'}">
                                    <button type="submit" name="action" value="fulfill" class="btn btn-sm btn-green">Mark fulfilled</button>
                                </c:if>
                            </form>
                        </c:if>
                        <c:if test="${r.status == 'FULFILLED' or r.status == 'REJECTED'}"><span class="muted small">Closed</span></c:if>
                    </td>
                </tr>
            </c:forEach>
            <c:if test="${empty requests}">
                <tr><td colspan="7" class="empty-row">No requests found.</td></tr>
            </c:if>
            </tbody>
        </table>
    </div>
</div>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
